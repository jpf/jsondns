$LOAD_PATH.push(File.dirname(__FILE__) + '/lib')
require 'dnsruby-jsonquery'
require 'sinatra'

resolver = Dnsruby::Resolver.new({:nameserver => "8.8.8.8"}) # Google DNS

get '/' do
  erb :index
end

get '/IN/:domain/:type' do
  answer = resolver.jsonquery(params[:domain],params[:type])
  if params[:callback]
    params[:callback] + '(' + answer + ')' # JSONP
  else
    answer
  end
end

get '/IN*' do
  resolver.jsonquery(nil,nil)
end
