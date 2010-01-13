class Hash
  # Used by to_dnsruby_message to convert a Hash into a new Dnsruby::Message
  def to_rdata_string   # this should actually be a monkeypatch to Dnsruby::RR "new_from_json_hash"
    throw SyntaxError unless defined? self[:name] and defined? self[:ttl] and defined? self[:class] and defined? self[:rdata]
    if self[:rdata].class == Array
      rdata = self[:rdata].join(' ') 
    else
      rdata = self[:rdata]
    end
    "%s %s %s %s %s" % [self[:name],self[:ttl],self[:class],self[:type],rdata]
  end

  # Given a hash (but should be a string), create a Dnsruby::Message
  def to_dnsruby_message # this should actually be a monkeypatch to Dnsruby::Message "new_from_json"?
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
