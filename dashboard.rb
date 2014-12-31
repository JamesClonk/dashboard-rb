require 'sinatra'
require "sinatra/reloader" if development?
Dir[File.dirname(__FILE__) + '/*.rb'].each {|file| require file}

set :public_folder, File.dirname(__FILE__) + '/assets'
set :views, settings.root + '/templates'

get '/' do
	@title = "Dashboard"
	erb :index
end

get '/api/:method' do
	data_handler(params[:method])
end

def data_handler(method)
	content_type 'application/json'
	case method
	when "hostname"
		hostname
	when "ip"
		ip_addresses
	when "cpu"
		cpu
	when "mem"
		mem
	when "disk"
		df
	when "processes"
		top
	when "top"
		top
	when "logged_on"
		logged_on
	when "users"
		passwd
	when "network"
		network
	else
		"{}"
	end
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
