class Location < ApplicationRecord
  # ── Associations ──────────────────────────────────────────────────────────
  belongs_to :city
  has_many :products,              dependent: :destroy
  has_many :conference_rooms,      -> { where(type: "ConferenceRoom") },      class_name: "Product"
  has_many :offices,               -> { where(type: "Office") },              class_name: "Product"
  has_many :virtual_offices,       -> { where(type: "VirtualOffice") },       class_name: "Product"
  has_many :company_headquarters,  -> { where(type: "CompanyHeadquarter") },  class_name: "Product"
  has_many :addons,                -> { where(type: "Addon") },               class_name: "Product"

  # ── Validations ───────────────────────────────────────────────────────────
  validates :name,              presence: true
  validates :city,              presence: true
  validates :zoho_location_id,  uniqueness: true, allow_nil: true

  # ── Scopes ────────────────────────────────────────────────────────────────
  scope :active, -> { where(active: true) }

  # ── Delegation ────────────────────────────────────────────────────────────
  delegate :currency, to: :city

  # ── Zoho Sync ─────────────────────────────────────────────────────────────
  def self.sync_from_zoho!(zoho_id:, name:, address:, language:, picture_id:,
                            phone:, email:, website:, city:, raw_payload: {})
    location = find_or_initialize_by(zoho_location_id: zoho_id)
    location.assign_attributes(
      name:           name,
      address:        address,
      language:       language,
      picture_id:     picture_id,
      phone:          phone,
      email:          email,
      website:        website,
      city:           city,
      synced_data:    raw_payload,
      last_synced_at: Time.current
    )
    location.save!
    location
  end

  def to_s
    "#{name} – #{city.name}"
  end
end
