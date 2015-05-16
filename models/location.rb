class Location < ActiveRecord::Base

  # Variables & Includes ------------------------------------------------------

  require 'addressable/uri'
  require 'redis'

  include Uuidable

  extend FriendlyId
  friendly_id :uuid, use: [:finders]

  include Paperclip::Glue
  has_attached_file :image, styles: {large: ["800x600>",:jpg]}


  # Associations --------------------------------------------------------------


  # Validations & Callbacks ---------------------------------------------------

  attr_accessor :image_remote_url

  validates :ip_address, presence: true #format: {with: /\A(?>(?>([a-f0-9]{1,4})(?>:(?1)){7}|(?!(?:.*[a-f0-9](?>:|$)){8,})((?1)(?>:(?1)){0,6})?::(?2)?)|(?>(?>(?1)(?>:(?1)){5}:|(?!(?:.*[a-f0-9]:){6,})(?3)?::(?>((?1)(?>:(?1)){0,4}):)?)?(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])(?>\.(?4)){3}))\z/i}
  validates :useragent, presence: true, length: {minimum: 2}
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\z/

  before_validation :image_from_url
  before_save :extract_dimensions
  after_create :geo_locate


  # Scopes --------------------------------------------------------------------

  scope :located,   -> { where('country IS NOT NULL AND lat IS NOT NULL AND lng IS NOT NULL') }
  scope :pictured,  -> { where('image_file_name IS NOT NULL AND image_file_size > 0') }
  scope :completed, -> { located.pictured }
  scope :latest,    -> { order('created_at DESC') }
  scope :on,        -> (v) { where('DATE(created_at) = ?', v) }
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
      puts "Unable to locate #{loc.ip_address}"
      raise
    end
  end


  # STEP 2: Get picture from Flickr based on location
  def self.photo_locate(id)
    page = 1
    loc = located.find(id) rescue nil
    return if loc.blank?

    # Do initial search for photos
    photos = flickr.photos.search(page: page, lat: loc.lat, lon: loc.lng, accuracy: 11, safe_search: 2, content_type: 1, license: '1,2,3,4,5,6,7,8,9,10')
    raise unless photos.count > 0

    # Lets get from a different page if random page is > 1. Continue on if error, as this is just to make results more interesting
    begin
      page = rand(photo.pages) if photos.page > 1
      photos = flickr.photos.search(page: page, lat: loc.lat, lon: loc.lng, accuracy: 9, safe_search: 2, content_type: 1, license: '1,2,3,4,5,6,7,8,9,10') if page > 1
    rescue
    end

    # Get photo
    selected_photo = photos.to_a.shuffle.first
    info = flickr.photos.getInfo(photo_id: selected_photo['id'], secret: selected_photo['secret'])
    sizes = flickr.photos.getSizes(photo_id: selected_photo['id'], secret: selected_photo['secret'])
    
    # Assign photo, try to get largest sizes
    source = nil
    ['Original', 'Large'].each do |s|
      sizes.each{|i| source = i['source'] if i['label'] == s}
      break unless source.blank?
    end
    raise if source.blank? # try again

    # Update with source info
    raise unless loc.update(
      image_remote_url:           source,
      image_source_url:           source,
      image_attribute_id:         info['id'],
      image_attribute_secret:     info['secret'],
      image_attribute_owner_id:   info['owner']['nsid'],
      image_attribute_owner_name: info['owner']['username'],
      image_attribute_license:    info['license'],
      image_attribute_title:      info['title'],
      image_attribute_taken_at:   info['dates']['taken'] || info['dates']['posted'],
      image_attribute_url:        "https://www.flickr.com/photos/#{info['owner']['username']}/#{info['id']}"
    )

    # Publish photo
    loc.publish_redis_status(:updated, :completed)

  rescue => err
    puts "ERROR: #{err}"
    return false
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
      id:       self.uuid,
      lat:      self.lat,
      lng:      self.lng,
      country:  self.country,
      address:  self.address,
      color:    color,
      image: {
        url:          self.image.url(:large),
        source_url:   self.image_source_url,
        link_url:     self.image_attribute_url,
        owner:        self.image_attribute_owner_name,
        title:        self.image_attribute_title,
        license:      self.image_attribute_license,
        taken_at:     self.image_attribute_taken_at,
        dimensions:   {
          width:      self.image_dimensions_width,
          height:     self.image_dimensions_height
        }
      }      
    }
  end

  def color
    ip = self.ip_address.split('.').shuffle
    {
      hex:    [ip[0].to_hex, ip[1].to_hex, ip[2].to_hex].join(''),
      alpha:  ip[3]
    }
  end


  # Call delayed geo_* and photo_* locate methods from record
  def geo_locate
    self.class.delay.geo_locate(self.id)
  end

  def photo_locate
    self.class.delay.photo_locate(self.id)
  end
  

protected

  def extract_dimensions
    return unless image?
    tempfile = image.queued_for_write[:original]
    unless tempfile.nil?
      geometry = Paperclip::Geometry.from_file(tempfile)
      self.image_dimensions_width = geometry.width.to_i
      self.image_dimensions_height = geometry.height.to_i
    end
  end

  def image_from_url
    return if image_remote_url.blank?

    begin
      uri = Addressable::URI.parse(image_remote_url)
      Timeout::timeout(30) do # 30 seconds
        io = open(uri, read_timeout: 30, "User-Agent" => 'b4u.today', allow_redirections: :all)
        io.class_eval { attr_accessor :original_filename }
        raise "invalid content-type" unless io.content_type.match(/^image\//i)
        io.original_filename = File.basename(uri.path)
        self.image = io
      end
    rescue OpenURI::HTTPError => err
      self.errors.add(:image, "unable to retrieve from URL #{image_remote_url} [e:1]")
    rescue Timeout::Error => err
      self.errors.add(:image, "unable to retrieve from URL #{image_remote_url} [e:2]")
    rescue => err
      self.errors.add(:image, "unable to retrieve from URL #{image_remote_url} (#{err})")
    end
  end


end