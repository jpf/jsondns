# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe Domain do
  it "properly parses the name" do
    name = 'five.four.three.two.tld'
    domain = Domain.new(name)
    domain.name.should == name
    domain.labels.should == ['five','four','three','two','tld']
    domain.tld.should == 'tld'
  end

  it "returns true for 'example.com'" do
    domain = Domain.new('example.com')
    domain.valid?.should == true
  end

  it "returns false if the domain name is empty ('')" do
    domain = Domain.new('')
    domain.valid?.should == false
  end

  # TODO: Test the entire ASCII range, not just printable characters.
  it "returns false if the domain name contains invalid characters" do
    invalid = '`~!@#$%^&*()=+[{]}\|;:\'",<>/?'.split(//) #'

    invalid.each do |char|
      domain = Domain.new(char + 'example.com')
      domain.valid?.should == false
    end # each
  end

  it "returns false if the domain name has no dots ('.')" do
    domain = Domain.new('monkeypants')
    domain.valid?.should == false
  end

  it "returns true if the name is 255 octets" do
    name = 'x' * 251 + '.com'
    domain = Domain.new(name)
    domain.valid?.should == false
  end

  it "returns false if the name is longer than 255 octets" do
    name = 'x' * 252 + '.com'
    domain = Domain.new(name)
    domain.valid?.should == false
  end

  it "returns false if the TLD is all numeric" do
    tlds = ['1','12','123','1234','42']
    tlds.each do |tld|
      domain = Domain.new('example.' + tld)
      domain.valid?.should == false
    end
  end

  it "returns false if any label in the name is longer than 63 octets" do
    tests = [
             'x' * 64 + '.three.two.tld',
             'four.' + 'x' * 64 + '.two.tld',
             'four.three' + 'x' * 64 + '.tld',
             'four.three.two.' + 'x' * 64
             ]
    tests.each do |test|
      domain = Domain.new(test)
      domain.valid?.should == false
    end
  end

  it "returns false if the name starts or ends with a dash ('-')" do
    tests = ['-example.com','example.com-']
    tests.each do |test|
      domain = Domain.new(test)
      domain.valid?.should == false
    end
  end

  it "returns true on valid domain names" do
    tests = ['example.com','jsondns.org']
    tests.each do |test|
      domain = Domain.new(test)
      domain.valid?.should == true
    end
  end

end # describe
