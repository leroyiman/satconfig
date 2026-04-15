class City < ApplicationRecord
  # ── Associations ──────────────────────────────────────────────────────────
  has_many :locations, dependent: :destroy
  has_many :products, through: :locations
  has_many :configurator_assignments, as: :assignable, dependent: :destroy

  # ── Validations ───────────────────────────────────────────────────────────
  validates :name,         presence: true
  validates :currency,     presence: true
  validates :zoho_city_id, uniqueness: true, allow_nil: true

  # ── Scopes ────────────────────────────────────────────────────────────────
  scope :active, -> { where(active: true) }

  # ── Override-Logik ────────────────────────────────────────────────────────
  # local_attributes überschreibt CRM-Direktfelder.
  # Beide Werte bleiben gespeichert (CRM-Feld + local_attributes-Key).

  def effective_name
    local_attributes["name"].presence || name
  end

  def effective_currency
    local_attributes["currency"].presence || currency
  end

  def override_attr!(key, value)
    self.local_attributes = (local_attributes || {}).merge(key.to_s => value.presence)
    save!
  end

  def reset_override!(key)
    self.local_attributes = (local_attributes || {}).except(key.to_s)
    save!
  end

  def overridden?(key)
    local_attributes&.key?(key.to_s) && local_attributes[key.to_s].present?
  end

  # ── Zoho Sync ─────────────────────────────────────────────────────────────
  def self.sync_from_zoho!(zoho_id:, name:, currency:, raw_payload: {})
    city = find_or_initialize_by(zoho_city_id: zoho_id)
    city.assign_attributes(
      name:           name,
      currency:       currency,
      synced_data:    raw_payload,
      last_synced_at: Time.current
    )
    city.save!
    city
  end

  def to_s
    "#{effective_name} (#{effective_currency})"
  end
end
