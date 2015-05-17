class Visit < ActiveRecord::Base

  # Variables & Includes ------------------------------------------------------

  include Uuidable

  extend FriendlyId
  friendly_id :uuid, use: [:finders]

  # Associations --------------------------------------------------------------

  belongs_to :location


  # Validations & Callbacks ---------------------------------------------------

  validates :ip_address, presence: true
  validates :useragent, presence: true, length: {minimum: 2}


  # Scopes --------------------------------------------------------------------

  scope :located,   -> { joins(:location).where('country IS NOT NULL AND country != ""').where('lat IS NOT NULL AND lng IS NOT NULL') }
  scope :pictured,  -> { joins(:location).where('image_file_name IS NOT NULL AND image_file_size > 0') }
  scope :completed, -> { located.pictured }
  scope :latest,    -> { order('visits.created_at DESC') }
  scope :on,        -> (v) { where('DATE(visits.created_at) = ?', v) }


  # Class Methods -------------------------------------------------------------

  def self.visit_offset; 5.minutes; end


  # Methods -------------------------------------------------------------------

  # Data to return
  def to_api
    location.to_api.merge(id: self.uuid)
  end


protected


end