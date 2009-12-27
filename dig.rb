$LOAD_PATH.push(File.dirname(__FILE__) + '/lib')
require 'dnsruby-jsonquery'

resolve = Dnsruby::Resolver.new({:nameserver => "8.8.8.8"}) # Google DNS
puts resolve.jsonquery(ARGV[0],ARGV[1])
