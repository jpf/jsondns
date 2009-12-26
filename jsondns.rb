# json-dig.rb
#
# Like dig(1) but returns data in the JSON format defined here: 
# http://github.com/jpf/eventdns/blob/master/envelope-format
#
# usage: ruby json-dig.rb example.com A
# TODO: Sort the output
# TODO: Allow for terse or human-readable data
# TODO: Include server and time in the output
# TODO: Fix the arcount
require 'rubygems'
require 'dnsruby'
require 'json'
require 'pp'
require 'sinatra'

class Dnsruby::Header
  def make_json(*args)
    rv = Hash.new()
    self.instance_variables.each do |key|
      value = self.instance_variable_get(key)
#      next if value == false
      rv[key.sub('@','')] = value
    end
    rv
  end # make_json
end

class Dnsruby::Question
  def make_json(*args)
    rv = Hash.new()
    ['qname','qtype','qclass'].each do |key|
      rv[key] = self.instance_variable_get('@' + key).to_s
    end
#    '{"QCLASS":"%s","QTYPE":"%s","QNAME":"%s"}' % [rv['qclass'],rv['qtype'],rv['qname']]
    rv
  end # make_json
end

class Dnsruby::RR
  def make_json(*args)
    rv = Hash.new()
    ['name','type','klass','ttl','rdata'].each do |key|
      value = self.instance_variable_get('@' + key)
      if key == 'klass'
        #FIXME: This should return if the class doesn't exist. Not this hardcoded hack.
        #return if value == 'CLASS1280'
        name = 'class'
      else
        name = key
      end
      rv[name] = value
    end
    rv
  end # make_json
end

class Array
  def make_json(*args)
    rv = Array.new()
    self.each do |element|
      value = element.make_json(*args)
      rv.push(value) if value
    end
    rv
  end
end

class Dnsruby::Message
  def make_json(*args)
    rv = Hash.new()
    ['header','question','answer','authority','additional'].each do |part|
      rv[part] = self.instance_variable_get('@' + part).make_json
     end
    rv
  end # make_json
end # Dnsruby::Message

include Dnsruby
#res = Dnsruby::Resolver.new({:nameserver => "4.2.2.2"})
res = Dnsruby::Resolver.new()
qdomain = 'example.com'
qtype = 'A'

get '/IN/:domain/:type' do
  qdomain = params[:domain]
  qtype = params[:type]
  message = Message.new(qdomain, Types.send(qtype))
  begin
    response = res.send_message(message)
  rescue ResolvError
    # TODO: twiddle the bits on the message with the correct DNS error codes
    response = message
    response.header.qr = true
    response.header.rcode = 'NXDOMAIN'
  rescue ResolvTimeout
    # TODO: twiddle the bits on the message with the correct DNS error codes
    response = message
    response.header.qr = true
    response.header.rcode = 'NXDOMAIN'
  end

  JSON.pretty_generate(response.make_json)
end


