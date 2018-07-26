# Reservation.rb 

class Reservation < ApplicationRecord
  include MultiparameterDateTime

  HOURS = (1..24).to_a

  multiparameter_date_time :start_time

  belongs_to :user
  belongs_to :option, optional: true
  belongs_to :studio
  belongs_to :coupon, optional: true
	
	has_many :issues

  validates :start_time,  presence: true, is_valid_multiparameter_date_time: true

  validates :start_time, :end_time, :overlap => { :query_options => {:is_payed => nil}, :scope => "studio_id",  :exclude_edges => ["start_time", "end_time"], :message_content => "Ce créneau a déjà été réservé. Merci d'en choisir un autre."}
	
  validates_datetime :start_time, :after => :now, :after_message => "Vous ne pouvez pas réserver dans le passé", if: :not_payed_yet? 

  validates_datetime :end_time, :after => :start_time, :after_message => "Vous ne pouvez pas finir avant d'avoir commencé", if: :not_payed_yet? 

  scope :is_payed, -> { where(state: "payed") }
	scope :is_not_payed, -> { where.not(state: "payed") }
	scope :is_canceled, -> { where(state: "cancel") }
	scope :current_user, -> { where(user: current_user) }
	
  def not_payed_yet?
    state == "created"
  end
	
	def duration
		(end_time - start_time) / 3600
	end
end

# place.rb

class Place < ApplicationRecord
  belongs_to :address

  has_many :place_features
  has_many :features, through: :place_features
	
	has_many_attached :images
	has_one_attached :guide

  validates :name,  presence: true, length: { maximum: 200 }
end

# studio.rb

class Studio < ApplicationRecord

  validates :photo, :attachment_presence => false

  belongs_to :place
  belongs_to :studio_type
  has_many :reservations
	
	has_many_attached :images
	has_one_attached :guide
	
  scope :by_city, -> (city) { joins(:place => {:address => :city}).where("city = ?", city) }
  scope :under_price, -> (price) { joins(:studio_type).where("price < ?", price) }

  scope :has_options, proc { |option|
    if option.present?
      where(have_options: true)
    end
  }

  scope :premium, proc { |premium|
    if premium.present?
      where(authorize_premium: true)
    end
  }

  validates :authorize_premium, :inclusion => {:in => [true, false]}
  validates :have_options, :inclusion => {:in => [true, false]}
  validates :description, length: { maximum: 4000 }
end
