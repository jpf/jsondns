# encoding: UTF-8
# A DNS server that services requests by asking an HTTP server for the answer.
#
# TODO: Write tests
# TODO: Write Dnsruby::Message#merge

require 'rubygems'
require 'logging'
require 'eventmachine'
require 'dnsruby'
require 'open-uri'
require 'yajl'
require 'pp'
include Dnsruby

$LOAD_PATH.push(File.dirname(__FILE__))
require 'lib/hash-to-dnsruby'
require 'lib/simplecache'
require 'lib/dnsruby-jsonquery'
require 'lib/dnsruby-valid'

# daemonize changes the directory to "/"
Dir.chdir(File.dirname(__FILE__))
# CONFIG = YAML.load_file('config.yml')
CONFIG = {
  :bind_address => '127.0.0.1',
  :bind_port => 1053,
  :log_level => :debug,
  :log_file => 'errors'
}

logfile = File.new(CONFIG[:log_file], 'a') # Always append
$logger = Logging.logger(logfile)
$logger.level = CONFIG[:log_level]

class DnsrubyError
  def initialize(message = Message.new)
    @message = message
    @message.header.qr = true
  end
  def format_error
    rv = @message
    rv.header.rcode = 'FORMERR'
    rv.encode
  end
  def server_failure
    rv = @message
    rv.header.rcode = 'SERVFAIL'
    rv.encode
  end
end

class JsonDns < EventMachine::Connection
  attr_accessor :host, :port

  def initialize
    $logger.debug "Started"
    @cache = SimpleCache.new
  end

  def new_connection
    # http://nhw.pl/wp/2007/12/07/eventmachine-how-to-get-clients-ip-address
    host = get_peername[2,6].unpack("nC4")
    @port = host.shift
    @host = host.join(".")
  end

  def process(data)
    begin
      message = Dnsruby::Message.decode(data).to_hash
    rescue Exception => e
      $logger.error "Error decoding message: #{e.inspect}"
      error = DnsrubyError.new
      return error.format_error
    end

    error = DnsrubyError.new(message.to_dnsruby_message)
    return error.format_error unless message.valid?

    # We can only handle one question per query right now.
    # This is what djbdns does ... but I'm not married to the idea.
    # The current URL structure only supports one question per query.
    q = message[:question][0]
    $logger.debug "#{@host}:#{@port.to_s} requested an #{q[:qtype]} record for #{q[:qname]}"

    #url = "http://dig.jsondns.org/IN/#{q[:qname]}/#{q[:qtype]}" # lol
    url = "http://bananatest.nfshost.com/IN/#{q[:qname]}/#{q[:qtype]}" # lol

    if cached_answer = @cache.get(url)
      message.overlay!(cached_answer)
      return message.to_dnsruby_message.encode
    end

    begin
      string = open(url).read
    rescue Exception => e
      $logger.error "Error reading #{url} (#{e.inspect})"
      # set the rcode to match the HTTP response code as approprate
      return error.server_failure
    end

    begin
      server_reply = Yajl::Parser.new(:symbolize_keys => true).parse(string)
    rescue Exception => e
      $logger.error "Error parsing JSON reply from #{url} (#{e.inspect})"
      return error.server_failure
    end

    reply_json = '{"header": {"aa": true}}'
    reply = Yajl::Parser.new(:symbolize_keys => true).parse(reply_json)

    reply_required_json = '{"header": {"qr": true,"opcode": "Query"}}'
    reply_required = Yajl::Parser.new(:symbolize_keys => true).parse(reply_required_json)

    begin
      reply.overlay!(server_reply)
      reply.overlay!(reply_required)
      message.overlay!(reply)
    rescue
      $logger.error "Error merging reply with query (#{e.inspect})"
      return error.server_failure
    end

    # Catch messages rendered invalid by the modifications above (A SOA reply with the AA flag set for example)
    return error.format_error unless message.valid?

    # TODO: Make sure that message.encode or message.valid? throw errors on messages that are too large, see also:
    # http://eventmachine.rubyforge.org/EventMachine/Connection.html#M000298
    begin
      answer = message.to_dnsruby_message.encode
    rescue Exception => e
      $logger.error "Error encoding reply (#{e.inspect})"
      return error.server_failure
    end

    # Only cache the message if it encodes without error
    ttl = message[:answer][0][:ttl]
    ttl = 10 unless ttl
    $logger.debug "cache miss for #{q[:qname]}/#{q[:qtype]} - caching reply for #{ttl} seconds"
    @cache.set(url,message,ttl)

    answer
  end

  def receive_data(data)
    new_connection

    begin
      reply = process(data)
    rescue
      # Handle unhandled exceptions ... we should never get this.
      $logger.error "Encountered unknown error while processing packet data"
      error = DnsrubyError.new
      reply = error.server_failure
    end

    begin
      send_datagram(reply, @host, @port)
    rescue Exception => e
      $logger.error "Error sending reply from #{url} (#{e.inspect})"
    end

  end # receive_data

  def shutdown
#    raise RuntimeError, "pid_file not defined in configuration" unless CONFIG[:pid_file]
#    File.delete(CONFIG[:pid_file])
  end # shutdown

end # JsonDns



#FIXME: On OS X (1Ghz PPC), queries take over 2000 miliseconds to complete. WTF?
EventMachine.run {
  connection = nil
  trap("INT") {
    $logger.info "ctrl+c caught, stopping server"
    connection.shutdown
    EventMachine.stop_event_loop
  }
  trap("TERM") {
    $logger.info "TERM caught, stopping server"
    connection.shutdown
    EventMachine.stop_event_loop
  }
  begin
    # These options are supposed to help things run better on Linux?
    # http://eventmachine.rubyforge.org/docs/EPOLL.html
    EventMachine.epoll
    EventMachine.kqueue
    connection = EventMachine.open_datagram_socket(CONFIG[:bind_address], CONFIG[:bind_port], JsonDns)
    $logger.info "jsondnsd started"
  rescue Exception => e
    $logger.fatal "#{e.inspect}"
    $logger.fatal e.backtrace.join("\r\n")
    $logger.fatal "Do you need root access?"
    EventMachine.stop_event_loop
  end
}
