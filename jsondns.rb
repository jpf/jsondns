# 
# jsondns.rb
#   Sinatra web application that provides a REST based DNS interface.
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
require 'sinatra'

def ttl_for(answer)
  ttl = 5 # set a 5 second ttl
  answer_hash = JSON.parse(answer)
  if answer_hash['header']['rcode'] == 'NOERROR' && answer_hash['answer'][0]
    ttl = answer_hash['answer'][0]['ttl']
  end
  ttl
end

resolver = Dnsruby::Resolver.new({:nameserver => "8.8.8.8"}) # Google DNS

get '/' do
  erb :index
end

get '/IN/:domain/:type' do
  answer = resolver.jsonquery(params[:domain],params[:type])
  response.headers['Cache-Control'] = 'public, max-age=' + ttl_for(answer).to_s
  if params[:callback] =~ /^[a-zA-Z_$][a-zA-Z0-9_$]*$/
    params[:callback] + '(' + answer + ')' # JSONP
  else
    answer
  end
end

get '/IN*' do
  resolver.jsonquery(nil,nil)
end
