require 'sinatra'
require 'curb'
require 'json'
require 'dalli'
require 'yaml'

CONF = YAML.load_file 'conf.yaml'
set :port, CONF['port']
set :bind, CONF['bind']
set :protection, :except => :frame_options

# memcached all the things
CACHE = Dalli::Client.new('localhost:11211', {
	:namespace => "cardify:10",
	:compress => true,
	:expires_in => 60
})

class Content
	attr_accessor :url, :title, :published, :trailtext, :byline
	attr_accessor :content_type, :tone, :byline_image, :author_name
	attr_accessor :author_url, :thumb

	def initialize path
		content = CACHE.get path
		return self.build(content) if content

		uri  = "#{CONF['content_api_host']}/#{path}?api-key=#{CONF['content_api_key']}&show-tags=tone,type,contributor&show-fields=headline,byline,trailText&show-elements=all"
		req  = Curl.get uri
		data = JSON.parse(req.body_str)['response']['content']

		CACHE.set path, data
		self.build(data)
	end

	# flatten an API response into a simple object
	def build data
		tones = data['tags'].select {|t| t['type'] == 'tone'}.map {|t| t['id'].gsub('tone/', '')}
		contributors = data['tags'].select {|t| t['type'] == 'contributor'}
		elements = data['elements']

		self.url = data['webUrl']
		self.title = data['fields']['headline']
		self.published = data['webPublicationDate']
		self.trailtext = data['fields']['trailText']
		self.byline = data['fields']['byline']
		self.content_type = data['tags'].find {|t| t['type'] == 'type'}['id'].gsub('type/', '')		
		self.tone = tones.find {|t| t == 'minutebyminute'} || tones.find {|t| t == 'comment'} || tones.find {|t| t == 'features' } || 'news'

		if contributors.length == 1
			self.byline_image = contributors[0]['bylineLargeImageUrl']
			self.author_name = contributors[0]['webTitle']
			self.author_url = contributors[0]['webUrl']
		end

		# deriving a thumb is torturous
		thumb_max_size = 380
		begin
			main_element = elements.find {|e| e['relation'] == 'main' }
			self.thumb = main_element['assets'].max_by {|a| w = a['typeData']['width'].to_i; w >= thumb_max_size ? 0 : w }['file']
		rescue
			begin
				self.thumb = elements.find {|e| e['type'] == 'video' }['assets'][0]['typeData']['stillImageUrl']
			rescue
				begin
					self.thumb = elements.find {|e| e['relation'] == 'gallery' }['assets'][0]['file']
				rescue; end
			end
		end
	end

	def to_oembed
		content = {
			provider_name: "The Guardian",
			provider_url: "http://www.theguardian.com/",
			version: "1.0", # oembed version – required
			type: "link"
		}

		[:url, :title, :published, :trailtext, :byline, :content_type,
			:tone, :byline_image, :author_name, :author_url].each do |k|
				content[k] = self.send(k)
			end

		content
	end
end

get %r{/html/(.+)} do
  path = params[:captures][0]
  content = Content.new path

  erb :html_embed, :locals => { :content => content }
end

get %r{/oembed/(.+)} do
  content_type "application/javascript"

  path = params[:captures][0]
  oembed = Content.new(path).to_oembed

  oembed['embed_link'] = "http://#{CONF['host']}:#{CONF['port']}/html/#{path}"
  oembed['stub'] = CGI.escapeHTML(erb(:stub, :locals => { :content => oembed }))

  if params[:callback]
  	"#{params[:callback]}(#{oembed.to_json})"
  else
  	oembed.to_json
  end
end