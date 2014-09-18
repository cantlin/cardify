require 'sinatra'
require 'curb'
require 'json'
require 'dalli'
require 'yaml'

CONF = YAML.load_file 'conf.yaml'
set :port, CONF['port']
set :bind, CONF['bind']
set :protection, :except => :frame_options

MEMCACHE_HOST = 'localhost:11211'
CACHE = Dalli::Client.new(MEMCACHE_HOST, { :namespace => "cardify:10", :compress => true, :expires_in => 60})

class ContentAPI
	def self.content_for_path path
		path.gsub! %r!https?:/?/www.theguardian.com/?!, ""
		content = CACHE.get path
		return self.oembed(content) if content

		uri = "#{CONF['content_api_host']}/#{path}?api-key=#{CONF['content_api_key']}&show-tags=tone,type,contributor&show-fields=headline,byline,trailText&show-elements=all"
		req  = Curl.get uri
		data = JSON.parse req.body_str
		response = data['response']['content']
		CACHE.set path, response
		self.oembed response
	end

	def self.oembed api_response
		content = {
			provider_name: "The Guardian",
			provider_url: "http://www.theguardian.com/",
			version: "1.0", # oembed version – required
			type: "link",
			url: api_response['webUrl'],
			title: api_response['fields']['headline'],
			published: api_response['webPublicationDate'],
			trailText: api_response['fields']['trailText'],
			byline: api_response['fields']['byline']
		}

		content[:content_type] = api_response['tags'].select {|t| t['type'] == 'type'}[0]['id'].gsub('type/', '')
		tones = api_response['tags'].select {|t| t['type'] == 'tone'}.map {|t| t['id'].gsub('tone/', '')}
		content[:tone] = tones.find {|t| t == 'minutebyminute'} || tones.find {|t| t == 'comment'} || tones.find {|t| t == 'features' } || 'news'
		contributors = api_response['tags'].select {|t| t['type'] == 'contributor'}

		if contributors.length == 1
			content[:byline_image] = contributors[0]['bylineLargeImageUrl']
			content[:author_name] = contributors[0]['webTitle']
			content[:author_url] = contributors[0]['webUrl']
		end

		elements = api_response['elements']
		begin
			main_element = elements.find {|e| e['relation'] == 'main' }
			content[:thumb] = main_element['assets'].max_by {|a| w = a['typeData']['width'].to_i; w >= 380 ? 0 : w }['file']
		rescue
			begin
				content[:thumb] = elements.find {|e| e['type'] == 'video' }['assets'][0]['typeData']['stillImageUrl']
			rescue
				begin
					content[:thumb] = elements.find {|e| e['relation'] == 'gallery' }['assets'][0]['file']
				rescue
				end
			end
		end

		content
	end
end

get %r{/html/(.+)} do
  path = params[:captures][0]
  content = ContentAPI.content_for_path(path)

  erb :html_embed, :locals => { :content => content }
end

get %r{/oembed/(.+)} do
  content_type "application/javascript"

  path = params[:captures][0]
  content = ContentAPI.content_for_path(path)
  content['embed_link'] = "http://#{CONF['host']}:#{CONF['port']}/html/#{path}"
  content['stub'] = CGI.escapeHTML(erb(:stub, :locals => { :content => content }))

  if params[:callback]
  	"#{params[:callback]}(#{content.to_json})"
  else
  	content.to_json
  end
end