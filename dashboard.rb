require 'sinatra'
require "sinatra/reloader" if development?
require 'json'
require 'socket'

set :public_folder, File.dirname(__FILE__) + '/assets'
set :views, settings.root + '/templates'

get '/' do
	@title = "Dashboard"
	erb :index
end

get '/api/hostname' do
	content_type 'application/json'
	hostname = {:Hostname => Socket.gethostname}
	#JSON.generate(hostname)
	hostname.to_json
end

get '/api/ip' do
	content_type 'application/json'
	ips = Array.new
	Socket.ip_address_list.each do |addr_info|
	 	if addr_info.ipv4? and !addr_info.ipv4_loopback? and !addr_info.ipv4_multicast?
	 		ips.push(addr_info.ip_address)
	 	end
	end
	ips.to_json
end

not_found do
	@title = "404 - Not Found"
	erb :not_found
end

error do
	@title = "500 - Internal Server Error"
	@error = env['sinatra.error']
	erb :error
end
