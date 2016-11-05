class WebApplication < Sinatra::Base

	class ImagesUploader < CarrierWave::Uploader::Base
		# storage :file
		storage :fog
		def store_dir
  			"uploads/#{ENV['RACK_ENV']}/#{model.id}"
		end
	end

	class Persona < Sequel::Model(:persona)
		mount_uploader :image, ImagesUploader
		plugin :timestamps, create: :created_at, update: :updated_at, update_on_create: true

		def get_watson_info
			age_min_watson = "??"
			age_max_watson = "??"
			gender_watson = "??"
			begin
				service = WatsonAPIClient::VisualRecognition.new(:api_key=> ENV["WATSON_API"], :version=>'2016-05-20')
				object = JSON.parse(service.detect_faces('url'=> self.image.url))

				img = object["images"].first
				face = img["faces"].first
				age_min_watson = face["age"]["min"]
				age_max_watson = face["age"]["max"]
				gender_watson = face["gender"]["gender"]
			ensure
				self.age_min = age_min_watson
				self.age_max = age_max_watson
				self.sex = gender_watson
				self.save
			end
		end
		def serealize
			{hash: self[:hash], age_min: self.age_min, age_max: self.age_max, gender: self.sex, costum_data: self.costum_data, image: self.image.url}
		end
	end

	class Order < Sequel::Model(:orders)
		plugin :timestamps, create: :created_at,update: :updated_at, update_on_create: true
		many_to_many :items
	end

	class Item < Sequel::Model(:items)
		plugin :timestamps, create: :created_at, update: :updated_at, update_on_create: true
		many_to_many :orders
	end




	configure do
		root = Settings.root_path

	    set :server, :thin                       # server or list of servers to use for built-in server
	    set :root, root                          # path to project root folder
	    set :views, root.join('views')           # path to the views folder
	    set :public_folder, root.join('public')  # path to the folder public files are served from

	    enable :dump_errors       # log exception backtraces to STDERR

	    disable :run              # enable/disable the built-in web server
	    disable :raise_errors     # allow exceptions to propagate outside of the app
	    disable :show_exceptions  # enable classy error pages
	    disable :method_override  # enable/disable the POST _method hack
	    disable :logging          # log requests to STDERR
	    enable :static           # disable static files serving

	    register Sinatra::Reloader if ENV['RACK_ENV'] == "development"
	end

	helpers Sinatra::StatusCodes,
	Sinatra::JSONUtils,
	Sinatra::HTMLUtils,
	Sinatra::ContentFor


	before do
		if ENV['RACK_ENV'] == "production"
			redirect request.url.sub('http', 'https') unless request.secure?
		end
	end

	helpers do
		def protected!
			return if authorized?
			headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
			halt 401, "Not authorized\n"
		end

		def authorized?
			@auth ||=  Rack::Auth::Basic::Request.new(request.env)
			@auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['admin', 'beam#Psw1']
		end
	end

	post "/persona/checkout/:id" do
		persona = Persona.first(hash: params[:id])
		mesage = {message: "person_removed", persona: persona.serealize}
	end 

	post "/persona/:id" do
		mesage = {}
		persona = Persona.first(hash: params[:id])
		if persona
			ap "found persona"
		else
			persona = Persona.new(hash: params[:id])
			persona.image = params[:file]
			persona.save
			persona.get_watson_info
		end	
		mesage = {message: "person_added", persona: persona.serealize, recent_purchases: {}, recommendation: {}}
		Settings.sockets.each{|s| s.send(mesage.to_json) }
		json OK, mesage.to_json
	end

	post "/checkout" do

	end

	get '/' do
		if !request.websocket?
			erb :index
		else
			request.websocket do |ws|
				ws.onopen do
					ws.send("Hello World!")
					Settings.sockets << ws
				end
				ws.onmessage do |msg|
					EM.next_tick { Settings.sockets.each{|s| s.send(msg) } }
				end
				ws.onclose do
					warn("websocket closed")
					Settings.sockets.delete(ws)
				end
			end
		end
	end


	Dir[Settings.root_path.join 'modules/**/*.rb'].each { |module_path| require module_path }

end
