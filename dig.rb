require 'dnsruby-jsonquery'
require 'pp'

resolve = Dnsruby::Resolver.new({:nameserver => "8.8.8.8"}) # Google DNS
#resolve = Dnsruby::Resolver.new()

puts resolve.jsonquery(ARGV[0],ARGV[1])
