# TODO: Sort the output?
# TODO: Print terse output
# TODO: Include server and time in the output

require 'rubygems'
require 'dnsruby'
require 'json'
include Dnsruby

class Dnsruby::Header
  def to_hash(*args)
    rv = Hash.new()
    self.instance_variables.each do |key|
      value = self.instance_variable_get(key)
      # I'm considering leaving out headers if they are false
      # next if value == false
      rv[key.sub('@','')] = value
    end
    rv
  end # to_hash
end

class Dnsruby::Question
  def to_hash(*args)
    rv = Hash.new()
    ['qname','qtype','qclass'].each do |key|
      rv[key] = self.instance_variable_get('@' + key).to_s
    end
    rv
  end # to_hash
end

class Dnsruby::RR
  def to_hash(*args)
    rv = Hash.new()
    ['name','type','klass','ttl','rdata'].each do |key|
      value = self.instance_variable_get('@' + key)
      name = key
      name = 'class' if key == 'klass'
      rv[name] = value
    end
    rv
  end # to_hash
end

class Dnsruby::Message
  def to_hash(*args)
    rv = Hash.new()
    ['header','question','answer','authority','additional'].each do |part|
      contents = self.instance_variable_get('@' + part).to_hash
      # TODO: Decide if we want to render empty fields to the output
      # rv[part] = contents unless contents.empty?
      rv[part] = contents
     end
    rv
  end # to_hash
  def cleanup()
    # Removes the annoying dnsruby OPT psudo-classes.
    # FIXME: There is quite likely a better way to do this!
    self.additional.delete_if { |rr| rr.klass.to_s.include?('CLASS') }
    self.update_counts
  end # cleanup
end # Dnsruby::Message

class Array
  def to_hash(*args)
    rv = Array.new()
    self.each do |element|
      value = element.to_hash(*args)
      rv.push(value) if value
    end
    rv
  end
end

class Dnsruby::Resolver
  def jsonquery(inname, intype='A')
    invalid_query = false
    
    # Validate domain name
    name = inname
    
    # Validate type
    begin
      type = Types.send(intype)
    rescue ArgumentError
      invalid_query = true
    end
    
    if invalid_query
      response = Message.new()
      response.header.qr = true
      response.header.rcode = 'FORMERR'
    else
      begin
        message = Message.new(name, type)
        response = self.send_message(message)
      rescue # ResolvError, ResolvTimeout
        # TODO: twiddle the bits on the message with the correct DNS error codes
        response = message
        response.header.qr = true
        response.header.rcode = 'NXDOMAIN'
      end # rescue
    end # else
    response.cleanup
    return JSON.pretty_generate(response.to_hash)
  end # def
end # class
