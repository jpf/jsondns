class Dnsruby::Message
  def valid?
    true # stub
  end
end

class Hash
  def overlay! (other)
    other[:header].each do |key,value|
      # Keep the original id
      next if key == :id
      # We calculate all the counts at the end
      next if key == :qdcount or key == :nscount or key == :ancount or key == :arcount

      self[:header][key] = value
    end

    [:question,:answer,:authority,:additional].each do |key|
      self[key] = other[key] if other[key]
    end

    self[:header][:qdcount] = self[:question].length if self[:question]
    self[:header][:nscount] = self[:authority].length if self[:authority]
    self[:header][:ancount] = self[:answer].length if self[:answer]
    self[:header][:arcount] = self[:additional].length if self[:additional]
  end
end

class Hash
  def valid?
    true # stub
  end
end
