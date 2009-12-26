require 'dnsruby-makejson'
require 'sinatra'

indomain = 'example.com'
intype = 'A'

get '/IN/:domain/:type' do
  resolvetojson(params[:domain],params[:type])
end


