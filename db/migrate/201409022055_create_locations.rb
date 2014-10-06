class CreateLocations < ActiveRecord::Migration

  def change
    create_table :locations do |t|
      t.string      :uuid
      t.string      :ip_address
      t.string      :useragent
      t.float       :lat
      t.float       :lng
      t.string      :country
      t.string      :address
      t.string      :image_file_name
      t.integer     :image_file_size
      t.string      :image_content_type
      t.datetime    :image_updated_at
      t.string      :image_source_url
      t.string      :image_attribute_id
      t.string      :image_attribute_owner_id
      t.string      :image_attribute_owner_name
      t.integer     :image_attribute_license
      t.string      :image_attribute_title
      t.datetime    :image_attribute_taken_at
      t.string      :image_attribute_url
      t.integer     :visits_count,            default: 0
      t.boolean     :active,                  default: true
      t.datetime    :last_visited_at
      t.timestamps
    end

    add_index :locations, [:uuid], unique: true
    add_index :locations, [:ip_address], unique: true
  end

end