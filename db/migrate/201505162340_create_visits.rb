class CreateVisits < ActiveRecord::Migration

  def up
    create_table :visits do |t|
      t.string      :uuid
      t.integer     :location_id
      t.string      :ip_address
      t.string      :useragent
      t.datetime    :created_at
    end

    add_index :visits, [:uuid], unique: true

    Location.all.each do |v|
      Visit.create(
        location_id:  v.id,
        ip_address:   v.ip_address,
        useragent:    v.useragent,
        created_at:   v.created_at
      )
    end

    remove_column :locations, :useragent
    remove_column :locations, :visits_count
    remove_column :locations, :last_visited_at
  end

  def down
    add_column :locations, :useragent, :string, after: :uuid
    add_column :locations, :visits_count, :integer, after: :image_attribute_url, default: 0
    add_column :locations, :last_visited_at, :datetime, before: :created_at

    Visit.all.each do |v|
      next if v.location.blank?
      v.location.update(useragent: v.useragent, visits_count: v.location.visits_count + 1, last_visited_at: v.created_at)
    end

    remove_index :visits, [:uuid]
    drop_table :visits
  end

end