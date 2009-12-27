#!/usr/bin/env ruby
# dig.rb
#   Command-line application to do DNS queries that return JSON.
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

$LOAD_PATH.push(File.dirname(__FILE__) + '/lib')
require 'dnsruby-jsonquery'

resolve = Dnsruby::Resolver.new({:nameserver => "8.8.8.8"}) # Google DNS
puts resolve.jsonquery(ARGV[0],ARGV[1])
