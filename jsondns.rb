require 'dnsruby-jsonquery'
require 'sinatra'

indomain = 'example.com'
intype = 'A'

res = Dnsruby::Resolver.new({:nameserver => "8.8.8.8"}) # Google DNS

get '/IN/:domain/:type' do
  res.jsonquery(params[:domain],params[:type])
end


