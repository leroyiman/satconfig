class Location < ApplicationRecord
  # ── Associations ──────────────────────────────────────────────────────────
  belongs_to :city
  has_many :products,              dependent: :destroy
  has_many :conference_rooms,      -> { where(type: "ConferenceRoom") },      class_name: "Product"
  has_many :offices,               -> { where(type: "Office") },              class_name: "Product"
  has_many :virtual_offices,       -> { where(type: "VirtualOffice") },       class_name: "Product"
  has_many :company_headquarters,  -> { where(type: "CompanyHeadquarter") },  class_name: "Product"
  has_many :addons,                -> { where(type: "Addon") },               class_name: "Product"
  has_many :configurator_assignments, dependent: :destroy

  # ── Validations ───────────────────────────────────────────────────────────
  validates :name,             presence: true
  validates :city,             presence: true
  validates :zoho_location_id, uniqueness: true, allow_nil: true

  # ── Scopes ────────────────────────────────────────────────────────────────
  scope :active, -> { where(active: true) }

  # ── Delegation ────────────────────────────────────────────────────────────
  delegate :currency, to: :city

  # ── Override-Logik ────────────────────────────────────────────────────────
  # Overridbare Felder: name, address, description, picture_id, phone, email, website
  # CRM-Direktfelder bleiben unberührt; local_attributes enthält die Overrides.

  OVERRIDABLE_FIELDS = %w[name address description picture_id phone email website].freeze

  def effective_name
    local_attributes["name"].presence || name
  end

  def effective_address
    local_attributes["address"].presence || address
  end

  def effective_description
    local_attributes["description"].presence
  end

  def effective_picture_id
    local_attributes["picture_id"].presence || picture_id
  end

  def effective_phone
    local_attributes["phone"].presence || phone
  end

  def effective_email
    local_attributes["email"].presence || email
  end

  def effective_website
    local_attributes["website"].presence || website
  end

  def effective_attr(key)
    local_attributes[key.to_s].presence || send(key.to_s)
  rescue NoMethodError
    local_attributes[key.to_s]
  end

  def override_attr!(key, value)
    self.local_attributes = (local_attributes || {}).merge(key.to_s => value.presence)
    save!
  end

  def reset_override!(key)
    self.local_attributes = (local_attributes || {}).except(key.to_s)
    save!
  end

  def reset_all_overrides!
    update!(local_attributes: {})
  end

  def overridden?(key)
    local_attributes&.key?(key.to_s) && local_attributes[key.to_s].present?
  end

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
    "#{effective_name} – #{city.name}"
  end
end
