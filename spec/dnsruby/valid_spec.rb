# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

require 'dnsruby'
require 'dnsruby-valid'

describe Dnsruby::Message do
#   before(:all) do
#     @msg = Dnsruby::Message.new
#   end

  it "has a valid? method" do
    msg = Dnsruby::Message.new
    msg.methods.include?('valid?').should == true
  end

end # describe
