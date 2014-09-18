require 'sinatra'
require 'yaml'
require 'json'
require 'curb'

CONF = YAML.load_file 'conf.yaml'
set :port, CONF['port']
set :bind, CONF['bind']

get '/' do
	erb :index, { locals: { api_root: CONF['api_root'] } }
end

get %r{/embed/(.+)} do
	path = params[:captures][0]
	erb :embed, { locals: { src: "#{CONF['api_root']}/html/#{path}" } }
end