# 
# dnsruby-jsonquery.rb
#   Monkeypatches to dnsruby to return DNS query results as JSON
#
# Copyright 2009 Joel Franusic
# 
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
# 
#        http://www.apache.org/licenses/LICENSE-2.0
# 
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#
# TODO: Sort the output?
# TODO: Print terse output
# TODO: Include server and time in the output

require 'rubygems'
require 'dnsruby'
require 'yajl'
$LOAD_PATH.push(File.dirname(__FILE__))
require 'domain'
require 'base64'
include Dnsruby

class Dnsruby::Header
  def to_hash(*args)
    rv = Hash.new
    self.instance_variables.each do |key|
      value = self.instance_variable_get(key)
      # NOTE: I'm considering leaving out headers if they are false, here is how I'd do that:
      ## next if value == false
      # This removes '@' from the key. I don't remember where that comes from, presumably
      # Dnsruby adds it?
      rv[key.to_s.sub('@','').to_sym] = value
    end
    rv
  end # to_hash
end

class Dnsruby::Question
  def to_hash(*args)
    rv = Hash.new
    ['qname','qtype','qclass'].each do |key|
      rv[key.to_sym] = self.instance_variable_get('@' + key).to_s
    end
    rv
  end # to_hash
end

class Dnsruby::RR
  def to_hash(*args)
    rv = Hash.new
    ['name','type','klass','ttl','rdata'].each do |key|
      value = self.instance_variable_get('@' + key)
      name = key
      name = 'class' if key == 'klass'

      if not value.is_a?Array
        rv[name.to_sym] = value
        next
      end

      # We need to check the contents of Array's for elements with non-printable characters, and base64 encode those elements
      rv[name.to_sym] = value.map do |element|
        if element.to_s =~ /[^[:print:]]/
          'data:application/octet-stream;base64,' + Base64.encode64(element).chomp
        else
          element.to_s
        end
      end # map

    end
    rv
  end # to_hash
end

class Dnsruby::Message
  def to_hash(*args)
    rv = Hash.new
    ['header','question','answer','authority','additional'].each do |part|
      contents = self.instance_variable_get('@' + part).to_hash
      # TODO: Decide if we want to render empty fields to the output
      # rv[part] = contents unless contents.empty?
      rv[part.to_sym] = contents
     end
    rv
  end # to_hash
  def cleanup
    # Removes the annoying dnsruby OPT psudo-classes.
    # FIXME: There is quite likely a better way to do this!
    self.additional.delete_if { |rr| rr.klass.to_s.include?('CLASS') }
    self.update_counts
  end # cleanup
end # Dnsruby::Message

class Array
  def to_hash(*args)
    rv = Array.new
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
    domain = Domain.new(inname)
    if domain.valid?
      name = domain.name
    else
      invalid_query = true
    end
    
    # Validate type
    begin
      type = Types.send(intype)
    rescue # ArgumentError, TypeError, ...
      invalid_query = true
    end
    
    if invalid_query
      response = Message.new
      response.header.qr = true
      response.header.rcode = 'FORMERR'
    else
      begin
        message = Message.new(name, type)
        response = self.send_message(message)
      rescue # ResolvError, ResolvTimeout, ...
        # TODO: twiddle the bits on the message with the correct DNS error codes
        response = message
        response.header.qr = true
        response.header.rcode = 'NXDOMAIN'
      end # rescue
    end # else
    response.cleanup
    return Yajl::Encoder.new(:pretty => true).encode(response.to_hash)
  end # def
end # class

