class City < ApplicationRecord
  # ── Associations ──────────────────────────────────────────────────────────
  has_many :locations, dependent: :destroy
  has_many :products, through: :locations

  # ── Validations ───────────────────────────────────────────────────────────
  validates :name,         presence: true
  validates :currency,     presence: true
  validates :zoho_city_id, uniqueness: true, allow_nil: true

  # ── Scopes ────────────────────────────────────────────────────────────────
  scope :active, -> { where(active: true) }

  # ── Zoho Sync ─────────────────────────────────────────────────────────────
  # Wird vom ZohoWebhookService aufgerufen.
  # Überschreibt nur CRM-Felder, nie manuelle App-Daten.
  def self.sync_from_zoho!(zoho_id:, name:, currency:, raw_payload: {})
    city = find_or_initialize_by(zoho_city_id: zoho_id)
    city.assign_attributes(
      name:          name,
      currency:      currency,
      synced_data:   raw_payload,
      last_synced_at: Time.current
    )
    city.save!
    city
  end

  def to_s
    "#{name} (#{currency})"
  end
end
