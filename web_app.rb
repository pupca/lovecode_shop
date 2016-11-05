class WebApplication < Sinatra::Base

	class ItemsUploader < CarrierWave::Uploader::Base
		# storage :file
		storage :fog
		def store_dir
			"uploads/#{ENV['RACK_ENV']}/#{model.class.to_s.underscore}/#{model.id}"
		end
	end

	class ImagesUploader < CarrierWave::Uploader::Base
		# storage :file
		storage :fog
		def store_dir
			"uploads/#{ENV['RACK_ENV']}/#{model.class.to_s.underscore}/#{model.id}"
		end
	end

	class Persona < Sequel::Model(:persona)
		mount_uploader :image, ImagesUploader

		plugin :timestamps, create: :created_at, update: :updated_at, update_on_create: true

		one_to_many :orders

		def get_watson_info
			age_min_watson = "??"
			age_max_watson = "??"
			gender_watson = "??"
			begin
				ap ENV["WATSON_API"]
				service = WatsonAPIClient::VisualRecognition.new(:api_key=> ENV["WATSON_API"], :version=>'2016-05-20')
				object = JSON.parse(service.detect_faces('url'=> self.image.url))

				img = object["images"].first
				face = img["faces"].first
				age_min_watson = face["age"]["min"]
				age_max_watson = face["age"]["max"]
				gender_watson = face["gender"]["gender"]
			rescue => e
				ap "error #{e}"
			ensure
				self.age_min = age_min_watson
				self.age_max = age_max_watson
				self.sex = gender_watson
				self.save
			end
		end

		def serealize
			{hash: self[:hash], email: self.email, name: self.name , age_min: self.age_min, age_max: self.age_max, gender: self.sex, custom_data: self.custom_data, image: self.image.url, celebrity: self.celebrity}
		end

		def recent_purchases
			message = []
			Order.where(persona_id: self.id)
			orders.each do |order|
				order.items.each do |item|
					message << item.serealize(order)
				end
			end
			return message
		end

		def inventory
			message = []
		
			items = Item.all
			items.each do |item|
				message << item.serealize
			end
			return message
		end

		def recommendation
			message = []
			recent_purchases = self.recent_purchases
			recent_purchases_ids = recent_purchases.collect{|item| item[:id]}.uniq

			if recent_purchases_ids.size > 0
			items = Item.where("id NOT IN ?", recent_purchases_ids)
			else
			items = Item.all
			end
			items.each do |item|
				message << item.serealize
			end

			return message
		end
	end

	class Order < Sequel::Model(:orders)
		plugin :timestamps, create: :created_at,update: :updated_at, update_on_create: true
		many_to_many :items
	end

	class Item < Sequel::Model(:items)
		mount_uploader :image_url, ItemsUploader
		plugin :timestamps, create: :created_at, update: :updated_at, update_on_create: true
		many_to_many :orders

		def serealize(order = nil)
			if order
				{id: self.id, name: self.name, image: self.image_url.url, category: self.category, price: self.price, purchased_at: order.created_at, created_at: self.created_at}
			else
				{id: self.id, name: self.name, image: self.image_url.url, category: self.category, price: self.price, created_at: self.created_at}
			end
		end
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

		if params[:persona]
			ap params[:persona]
			persona.name = params[:persona][:name] if params[:persona][:name]
			persona.email = params[:persona][:email] if params[:persona][:email]
			persona.celebrity = params[:persona][:celebrity] if params[:persona][:celebrity]
			persona.custom_data = params[:persona][:custom_data] if params[:persona][:custom_data]
			persona.save
		end

		items = params[:items]
		if items && items.size > 0
			order = Order.create(persona_id: persona.id)
			items.each do |item_id|
				item = Item.first(id: item_id)
				if item
					order.add_item(item)
				end
			end
		end
		mesage = {type: "person_removed", data: {persona: persona.serealize}}
		Settings.sockets.each{|s| s.send(mesage.to_json) }
		json OK, mesage.to_json
	end 

	post "/persona/:id" do
		mesage = {}
		persona = Persona.first(hash: params[:id])
		unless persona
			persona = Persona.new(hash: params[:id], last_seen_at: Time.now - 1.year)
			persona.image = params[:file]
			persona.save
			persona.get_watson_info
		end

		mesage = {type: "person_added", data: {persona: persona.serealize, recent_purchases: persona.recent_purchases, recommendation: persona.recommendation, inventory: persona.inventory}}
		if persona.last_seen_at < Time.now - 1.second
			puts "Sending Socket!!!!!!!!!"
			Settings.sockets.each{|s| s.send(mesage.to_json) }
		end
		persona.update(last_seen_at: Time.now)		
		json OK, mesage.to_json
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

	get "/s" do
		persona = Persona.first
		persona.recommendation
		json OK, {}

	end

	get "/camera" do
		erb :camera
	end

	get "/seed" do
		Item.all.collect(&:destroy)
		Order.all.collect(&:destroy)
		unless Persona.all.size > 0
			persona = Persona.create(hash: "pupca", last_seen_at: Time.now, image: Pathname.new(File.dirname(__FILE__) + "/doc/persona01.jpg").open)
			persona.get_watson_info
		end

		Settings.database.run("DELETE FROM items_orders;")

		item = Item.create(name: "Denim Jeans", price: 12000, category: "pants", image_url: Pathname.new(File.dirname(__FILE__) + "/doc/01.jpeg").open)
		item = Item.create(name: "Fuzzy Slippers", price: 80000, category: "shoes", image_url: Pathname.new(File.dirname(__FILE__) + "/doc/02.jpeg").open)
		item = Item.create(name: "Fancy Hat", price: 4000, category: "accessories", image_url: Pathname.new(File.dirname(__FILE__) + "/doc/03.jpeg").open)

		items = Item.all

		Persona.each do |persona|
			(rand(5) + 1).times do |number|
				order = Order.create(persona_id: persona.id)
				(rand(5) + 1).times do |n|
					item = items[rand(items.count - 1)]
					order.add_item(item)
				end
			end
		end

		item = Item.create(name: "Denim Jacket", price: 40000, category: "tops", image_url: Pathname.new(File.dirname(__FILE__) + "/doc/04.jpeg").open)
		
		json OK, {}
	end

end
