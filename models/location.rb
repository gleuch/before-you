class Location < ActiveRecord::Base

  # Variables & Includes ------------------------------------------------------

  require 'addressable/uri'
  require 'redis'

  include Uuidable

  extend FriendlyId
  friendly_id :uuid, use: [:finders]

  include Paperclip::Glue
  has_attached_file :image, styles: {}


  # Associations --------------------------------------------------------------


  # Validations & Callbacks ---------------------------------------------------

  validates :ip_address, presence: true #format: {with: /\A(?>(?>([a-f0-9]{1,4})(?>:(?1)){7}|(?!(?:.*[a-f0-9](?>:|$)){8,})((?1)(?>:(?1)){0,6})?::(?2)?)|(?>(?>(?1)(?>:(?1)){5}:|(?!(?:.*[a-f0-9]:){6,})(?3)?::(?>((?1)(?>:(?1)){0,4}):)?)?(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])(?>\.(?4)){3}))\z/i}
  validates :useragent, presence: true, length: {minimum: 2}
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\z/

  after_create :geo_locate


  # Scopes --------------------------------------------------------------------

  scope :located,   -> { where('country IS NOT NULL AND lat IS NOT NULL AND lng IS NOT NULL') }
  scope :pictured,  -> {where('image_file_name IS NOT NULL AND image_file_size > 0') }
  scope :completed, -> { located.pictured }
  scope :latest,    -> { order('created_at DESC') }
  default_scope     -> { where(active: true) }


  # Class Methods -------------------------------------------------------------

  # Channel name for redis pub/sub
  def self.redis_channel; 'b4u-list'; end


  # STEP 1: Get geo info
  def self.geo_locate(id)
    loc = find(id) rescue nil
    return if loc.blank?

    # Skip and queue photo query if previously located.
    if loc.located?
      loc.photo_locate unless loc.pictured?
      return
    end

    # Locate geography from IP address
    geo = Geocoder.search(loc.ip_address).first rescue nil
    if geo.present? && geo.data.present?
      addy = %w(city region_name country_name).map{|n| geo.data[n]}.reject(&:blank?).compact
      unless addy.include?('Reserved')
        loc.update(lat: geo.data['latitude'], lng: geo.data['longitude'], country: geo.data['country_code'], address: addy.join(', '))
        loc.photo_locate
      else
        loc.update(address: 'Reserved', country: 'RD', lat: 0.0, lng: 0.0)
      end

      loc.publish_redis_status(:updated)

    else
      raise "Unable to locate #{loc.ip_address}"
    end
  end


  # STEP 2: Get picture from Flickr based on location
  def self.photo_locate(id)
    loc = find(id) rescue nil
    return if loc.blank?

    # Flickr photo here
    #photos = flickr.photos.search(lat: loc.lat, lon: loc.lng, license: '1,2,3,4,5,6,7,8')

    loc.publish_redis_status(:updated, :completed)
  end



  # Methods -------------------------------------------------------------------

  # Pub/sub name for location
  def redis_channel; ['b4u',self.uuid].join('-'); end


  # Publish response to redis
  def publish_redis_status(*args)
    uri = URI.parse('redis://localhost:6379')
    redis = Redis.new(host: uri.host, port: uri.port, password: uri.password)

    args.each do |arg|
      case arg.to_s
        when 'completed'
          redis.publish(self.class.redis_channel, JSON.generate( to_api ))
        when 'updated'
          redis.publish(redis_channel, JSON.generate( to_api ))
      end
    end
  end


  # Does location have geo info?
  def located?; self.lat.present? && self.lng.present? && self.country.present?; end


  # Is it a reserved (192.*.*.* or other known private-level IP address)
  def reserved?; self.located? && self.country == 'RD'; end


  # Does location have picture?
  def pictured?; self.image_file_name.present? && self.image_file_size > 0; end


  # Has been located and pictured?
  def completed?; located? && pictured?; end


  #
  def location
    return t(:location_not_known) unless located?
    self.address.present? ? self.address : (self.country_name.present? ? self.country : [self.lat, self.lng].join(', '))
  end


  # Track the last visit and visits count by this ip address.
  def impression!
    self.update(visits_count: (self.visits_count || 0) + 1, last_visited_at: Time.now)
  end


  # Data to return
  def to_api
    {
      id: self.uuid,
      lat: self.lat,
      lng: self.lng,
      country: self.country,
      address: self.address,
      image: {
        url:          self.image.url,
        source_url:   self.image_source_url,
        owner:        self.image_attribute_owner_name,
        title:        self.image_attribute_title,
        license:      self.image_attribute_license,
        taken_at:     self.image_attribute_taken_at
      }      
    }
  end


  # Call delayed geo_ and photo_ locate methods from record
  def geo_locate; self.class.delay_for(1.second).geo_locate(self.id); end
  def photo_locate; self.class.delay_for(1.second).photo_locate(self.id); end
  

protected

end