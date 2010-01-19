# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

require 'dnsruby'
require 'dnsruby-jsonquery'

describe Dnsruby::Header do
  it "has a to_hash method" do
    msg = Dnsruby::Header.new
    msg.methods.include?('to_hash').should == true
  end
end # describe

describe Dnsruby::Question do
  it "has a to_hash method" do
    msg = Dnsruby::Question.new('example.com')
    msg.methods.include?('to_hash').should == true
  end
end # describe

describe Dnsruby::RR do
  it "has a to_hash method" do
    msg = Dnsruby::RR.new
    msg.methods.include?('to_hash').should == true
  end
end # describe

describe Dnsruby::Message do
  it "has a to_hash method" do
    msg = Dnsruby::Message.new
    msg.methods.include?('to_hash').should == true
  end
end # describe

describe Array do
  it "has a to_hash method" do
    msg = Array.new
    msg.methods.include?('to_hash').should == true
  end
end # describe

describe Dnsruby::Resolver do
  it "has a jsonquery method" do
    msg = Dnsruby::Resolver.new
    msg.methods.include?('jsonquery').should == true
  end
end # describe

