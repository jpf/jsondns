class SimpleCache
  @storage = nil
  def initialize
    @storage = {}
  end
  def set(key,value,expire_seconds=30)
    @storage[key] = [Time.now + expire_seconds, value]
  end
  def get(key)
    return nil unless @storage[key]
    
    if @storage[key][0] > Time.now
      return @storage[key][1]
    else
      @storage.delete(key)
    end
    return nil
  end
end
