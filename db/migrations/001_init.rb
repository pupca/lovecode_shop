require 'sequel_postgresql_triggers'

Sequel.migration do
	change do

    ############
    # Users
    ############

    create_table :items do
    	primary_key :id

    	column :name, String, null: true 
    	column :image_url, String, null: true 
        column :category, String, null: true
    	column :price, Integer, default: 0
        
    	column :created_at, 'timestamp without time zone', null: false
    	column :updated_at, 'timestamp without time zone', null: false
    end

    create_table :persona do
    	primary_key :id
        column :hash, String, null: true
        column :name, String, null: true
        column :email, String, null: true
        column :age_min, String, null: true
        column :age_max, String, null: true
        column :sex, String, null: true
        column :image, String, null: true

        column :costum_data, "json", default: "{}"

        column :celebrity, "boolean", default: false
    	column :created_at, 'timestamp without time zone', null: false
    	column :updated_at, 'timestamp without time zone', null: false

        index [:hash]
    end

    create_table :orders do
        primary_key :id

        column :persona_id, Integer
        column :created_at, 'timestamp without time zone', null: false
        column :updated_at, 'timestamp without time zone', null: false
    end

    create_table :items_orders do
        primary_key :id


        column :order_id, Integer
        column :item_id, Integer
    end

end
end
