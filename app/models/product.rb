class Product < ApplicationRecord
  # ── STI ───────────────────────────────────────────────────────────────────
  self.inheritance_column = :type

  TYPES = %w[ConferenceRoom Office VirtualOffice CompanyHeadquarter Addon].freeze

  # ── Associations ──────────────────────────────────────────────────────────
  belongs_to :location
  has_many   :product_translations,    dependent: :destroy
  has_many   :configurator_assignments, dependent: :destroy

  # ── Validations ───────────────────────────────────────────────────────────
  validates :type,            presence: true, inclusion: { in: TYPES }
  validates :location,        presence: true
  validates :zoho_product_id, uniqueness: true, allow_nil: true

  # ── Scopes ────────────────────────────────────────────────────────────────
  scope :active,    -> { where(active: true) }
  scope :by_type,   ->(t) { where(type: t) }
  scope :for_location, ->(loc) { where(location: loc) }

  # ── Delegation ────────────────────────────────────────────────────────────
  delegate :city,     to: :location
  delegate :currency, to: :location

  # ────────────────────────────────────────────────────────────────────────
  # EFFECTIVE ATTRIBUTE LOGIC
  # local_attributes überschreibt crm_attributes, Key für Key.
  # Beide Werte bleiben immer gespeichert.
  # ────────────────────────────────────────────────────────────────────────

  # Gibt den zusammengeführten Hash zurück (lokale Overrides haben Vorrang)
  def effective_attributes
    (crm_attributes || {}).merge((local_attributes || {}).compact)
  end

  # Gibt den effektiven Wert für einen einzelnen Key zurück
  def effective_attr(key)
    local_attributes&.dig(key.to_s) || crm_attributes&.dig(key.to_s)
  end

  # Setzt einen lokalen Override ohne den CRM-Wert zu verändern
  def override_attr!(key, value)
    self.local_attributes = (local_attributes || {}).merge(key.to_s => value)
    save!
  end

  # Entfernt einen lokalen Override (CRM-Wert gilt wieder)
  def reset_override!(key)
    self.local_attributes = (local_attributes || {}).except(key.to_s)
    save!
  end

  # Entfernt alle lokalen Overrides
  def reset_all_overrides!
    update!(local_attributes: {})
  end

  # Prüft, ob ein Feld lokal überschrieben wurde
  def overridden?(key)
    local_attributes&.key?(key.to_s)
  end

  # ────────────────────────────────────────────────────────────────────────
  # TRANSLATION HELPERS
  # ────────────────────────────────────────────────────────────────────────

  # Gibt die Übersetzung für eine Sprache zurück (oder nil)
  def translation_for(language)
    product_translations.find_by(language: language.to_s)
  end

  # Gibt den effektiven Namen zurück – mit Sprach-Fallback
  # 1. Lokaler Override der Übersetzung
  # 2. CRM-Übersetzung
  # 3. Kein Fallback – nil (bewusst, damit die UI erkennt, was fehlt)
  def effective_name(language = nil)
    if language
      translation_for(language)&.effective_name
    else
      effective_attr("name")
    end
  end

  # Gibt die effektive Description zurück – mit Sprach-Fallback
  def effective_description(language = nil)
    if language
      translation_for(language)&.effective_description
    else
      effective_attr("description")
    end
  end

  # ────────────────────────────────────────────────────────────────────────
  # ZOHO SYNC
  # Wird vom ZohoWebhookService aufgerufen.
  # WICHTIG: local_attributes wird NIE angefasst.
  # ────────────────────────────────────────────────────────────────────────

  def sync_from_zoho!(attributes_hash, translations_array = [], raw_payload = {})
    self.crm_attributes  = attributes_hash
    self.synced_data     = raw_payload
    self.last_synced_at  = Time.current
    save!

    translations_array.each do |t|
      trans = product_translations.find_or_initialize_by(language: t[:language].to_s)
      trans.crm_name        = t[:name]
      trans.crm_description = t[:description]
      trans.save!
    end

    self
  end

  def to_s
    effective_attr("name") || "#{type} ##{id}"
  end
end
