class Location < ActiveRecord::Base

  # Variables & Includes ------------------------------------------------------

  require 'addressable/uri'

  include Uuidable

  extend FriendlyId
  friendly_id :uuid, use: [:finders]

  include Paperclip::Glue
  has_attached_file :image, styles: {}

  # geocoded_by :ip_address


  # Associations --------------------------------------------------------------


  # Validations & Callbacks ---------------------------------------------------

  validates :ip_address, presence: true #format: {with: /\A(?>(?>([a-f0-9]{1,4})(?>:(?1)){7}|(?!(?:.*[a-f0-9](?>:|$)){8,})((?1)(?>:(?1)){0,6})?::(?2)?)|(?>(?>(?1)(?>:(?1)){5}:|(?!(?:.*[a-f0-9]:){6,})(?3)?::(?>((?1)(?>:(?1)){0,4}):)?)?(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])(?>\.(?4)){3}))\z/i}
  validates :useragent, presence: true, length: {minimum: 2}
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\z/

  after_create :queue_process


  # Scopes --------------------------------------------------------------------

  scope :located,   -> { where('country IS NOT NULL AND lat IS NOT NULL AND lng IS NOT NULL') }
  scope :pictured,  -> {where('image_file_name IS NOT NULL AND image_file_size > 0') }
  scope :completed, -> { located.pictured }
  scope :latest,    -> { order('created_at DESC') }
  default_scope     -> { where(active: true) }


  # Class Methods -------------------------------------------------------------


  # Methods -------------------------------------------------------------------

  # TODO: USE SIDEKIQ
  def queue_process
    process_step_one
  end

  # Does location have geo info?
  def located?; self.lat.present? && self.lng.present? && self.country.present?; end

  # Does location have picture?
  def pictured?; self.image_file_name.present? && self.image_file_size > 0; end

  def location
    return t(:location_not_known) unless located?
    self.address.present? ? self.address : (self.country_name.present? ? self.country : [self.lat, self.lng].join(', '))
  end

  # Track the last visit and visits count by this ip address.
  def impression!
    self.update(visits_count: (self.visits_count || 0) + 1, last_visited_at: Time.now)
  end


protected

  # STEP 1: Get geo info
  def process_step_one
    geo = Geocoder.search(ip_address).first rescue nil
    puts geo.inspect
    if geo.present? && geo.data.present?
      addy = %w(city region_name country_name).map{|n| geo.data[n]}.compact.join(', ')
      self.update(lat: geo.data['latitude'], lng: geo.data['longitude'], country: geo.data['country_code'], address: addy)

      process_step_two
    else
      puts "NOT FOUND"
      # requeue for later
    end
  end

  # STEP 2: Get picture from Flickr based on location
  def process_step_two
    # Get picture here
  end

end