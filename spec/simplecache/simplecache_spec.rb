# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe SimpleCache do
  before(:all) do
    @cache = SimpleCache.new()
  end

  it "can set a key and then get the same key" do
    @cache.set(:set_get,:xyzzy)
    @cache.get(:set_get).should == :xyzzy
  end

  it "will set a key for -1 seconds and return nil on a get for same" do
    @cache.set(:test,'testing',-1)
    @cache.get(:test).should == nil
  end

  it "will expire a key after 0.2 seconds" do
    @cache.set(:expire_1sec,:intheblinkofaneye,0.2)
    @cache.get(:expire_1sec).should == :intheblinkofaneye
    sleep 0.3
    @cache.get(:expire_1sec).should == nil
  end

  it "can use strings up to 2**16 in size as keys" do
    16.times do |power|
      key = 'x' * 2**power
      value = power
      @cache.set(key,value)
      @cache.get(key).should == value
    end
  end

  it "can use strings up to 2**16 in size as values" do
    16.times do |power|
      key = power
      value = 'x' * 2**power
      @cache.set(key,value)
      @cache.get(key).should == value
    end
  end

end # describe
