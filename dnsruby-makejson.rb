require 'rubygems'
require 'dnsruby'
require 'json'
include Dnsruby

class Dnsruby::Header
  def make_json(*args)
    rv = Hash.new()
    self.instance_variables.each do |key|
      value = self.instance_variable_get(key)
      # I'm considering leaving out headers if they are false
      # next if value == false
      rv[key.sub('@','')] = value
    end
    # FIXME: This is a hack to fix the weird non 'IN' classes that show up in the additional section.
    # rv['arcount'] = rv['arcount'] - 1
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
        # FIXME: This is a hack to fix the weird non 'IN' classes that show up in the additional section.
        # return unless value == 'IN'
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

def resolvetojson(indomain, intype)
  res = Dnsruby::Resolver.new({:nameserver => "8.8.8.8"}) # Google DNS

  invalid_query = false

  # Validate domain name
  qdomain = indomain
  
  # Validate type
  begin
    qtype = Types.send(intype)
  rescue ArgumentError
    puts 'Invalid type!'
    invalid_query = true
  end

  if invalid_query
    response = Message.new()
    response.header.qr = true
    response.header.rcode = 'FORMERR'
  else
    begin
      message = Message.new(qdomain, qtype)
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
  end
  return JSON.pretty_generate(response.make_json)
end
