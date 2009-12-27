require 'dnsruby-jsonquery'
require 'sinatra'

resolver = Dnsruby::Resolver.new({:nameserver => "8.8.8.8"}) # Google DNS

get '/' do
  erb :index
end

get '/IN/:domain/:type' do
  resolver.jsonquery(params[:domain],params[:type])
end

get '/IN*' do
  resolver.jsonquery(nil,nil)
end
