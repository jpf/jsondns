# encoding: UTF-8

require 'rubygems'
require 'logging'
require 'eventmachine'
require 'dnsruby'
require 'open-uri'
require 'yajl'
require 'pp'
include Dnsruby

class Hash
  # hmm .. this should actually be a monkeypatch to Dnsruby::RR "new_from_json_hash"?
  def to_rdata_string
    throw SyntaxError unless defined? self[:name] and defined? self[:ttl] and defined? self[:class] and defined? self[:rdata]
    if self[:rdata].class == Array
      rdata = self[:rdata].join(' ') 
    else
      rdata = self[:rdata]
    end
    "%s %s %s %s %s" % [self[:name],self[:ttl],self[:class],self[:type],rdata]
  end
  
  # hmm .. this should actually be a monkeypatch to Dnsruby::Message "new_from_json"?
  def to_dnsruby_message
    throw SyntaxError unless defined? self[:header] and defined? self[:question] and defined? self[:answer] and defined? self[:authority]
    msg = Message.new
    header = Header.new
    self[:header].each do |k,v|
      key = "@#{k}"
      next unless header.instance_variable_defined?(key)
      if k == :opcode
        header.opcode = v
      elsif k == :rcode
        header.rcode = v
      else
        header.instance_variable_set(key,v)
      end
    end
    msg.header = header
    
    self[:question].each do |q|
      msg.add_question(Question.new(q[:qname],q[:qtype],q[:qclass]))
    end
    
    self[:answer].each do |rr|
      msg.add_answer(RR.new_from_string(rr.to_rdata_string))
    end
    
    self[:authority].each do |rr|
      msg.add_authority(RR.new_from_string(rr.to_rdata_string))
    end
    
    self[:additional].each do |rr|
      msg.add_additional(RR.new_from_string(rr.to_rdata_string))
    end
    msg
  end # to_dnsruby_message
end # Hash

# $LOAD_PATH.push(File.dirname(__FILE__))

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

class EventDns < EventMachine::Connection
  @backend = nil
  attr_accessor :host, :port
  def initialize
    $logger.debug "Started"
  end

  # Is this this needed?
  def new_connection
    # http://nhw.pl/wp/2007/12/07/eventmachine-how-to-get-clients-ip-address
    host = get_peername[2,6].unpack("nC4")
    @port = host.shift
    @host = host.join(".")
  end

  # Is this strictly needed?
  def client_info
    host+":"+port.to_s
  end
  
  def receive_data(data)
    new_connection

    # this should be part of the .valid? method
    return unless data.size > 0

    begin
      packet = Dnsruby::Message.decode(data)
    rescue Exception => e
      $logger.error "Error decoding packet: #{e.inspect}"
      # return_error(FORMERR)
      return
    end

    # return_error(FORMERR) unless packet.valid?

    # We can only handle one question per query right now
    # This is what djbdns does ... don't have strong reasons either way other than that
    # the current URL structure only supports one question per query
    q = packet.question[0]
    $logger.debug "#{client_info} requested an #{q.qtype} record for #{q.qname}"

    # check for reply in cache, return if found

    # This should be a merge or add.
    id = packet.header.id
    url = "http://dig.jsondns.org/IN/#{q.qname}/#{q.qtype}" # lol
    string = open(url).read
    # set the rcode to match the HTTP response code as approprate
    # send SERVFAIL if the server doesn't respond
    packet = Yajl::Parser.new(:symbolize_keys => true).parse(string).to_dnsruby_message
    # send SERVFAIL if we have trouble decoding the JSON
    packet.header.id = id

    # return_error(FORMERR) unless reply.valid?
    # update cache

    # reply = open(url).read.to_dnsruby_message
    # packet.merge(reply)

    # flip AA and QR bits as approprate

    # return_error(FORMERR) unless packet.valid?

    # try: datagram = packet.encode
    # rescue: send FORMERR
    
    begin
      send_datagram(packet.encode, host, port)
    rescue Exception => e
      $logger.error "Error decoding packet: #{e.inspect}"
      #$logger.error e.backtrace.join("\r\n")
      # return_error(FORMERR) # or something
    end

  end # receive_data

  def shutdown
#    raise RuntimeError, "pid_file not defined in configuration" unless CONFIG[:pid_file]
#    File.delete(CONFIG[:pid_file])
  end # shutdown

end # EventDns



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
    connection = EventMachine.open_datagram_socket(CONFIG[:bind_address], CONFIG[:bind_port], EventDns)
    $logger.info "EventDns started"
#    $logger.debug "Backend is: '#{CONFIG[:backend]}'"
  rescue Exception => e
    $logger.fatal "#{e.inspect}"
    $logger.fatal e.backtrace.join("\r\n")
    $logger.fatal "Do you need root access?"
    EventMachine.stop_event_loop
  end
}
