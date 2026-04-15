class Addon < Product
  # ────────────────────────────────────────────────────────────────────────
  # CRM-Attribute (gespeichert in crm_attributes jsonb):
  #   name, billing_type, category, unit, applies_to (Array), price_per_location
  #
  # applies_to: Array mit Produkt-Typ-Strings, z.B.:
  #   ["Office", "VirtualOffice", "CompanyHeadquarter", "ConferenceRoom"]
  #
  # Übersetzungen (product_translations):
  #   language, crm_name / local_name, crm_description / local_description
  # ────────────────────────────────────────────────────────────────────────

  VALID_BILLING_TYPES = %w[monthly one_time per_use yearly].freeze
  VALID_APPLIES_TO    = %w[ConferenceRoom Office VirtualOffice CompanyHeadquarter].freeze

  # ── Attribut-Methoden ─────────────────────────────────────────────────────

  def price_per_location
    effective_attr("price_per_location")&.to_d
  end

  def billing_type
    effective_attr("billing_type")
  end

  def category
    effective_attr("category")
  end

  def unit
    effective_attr("unit")
  end

  # Gibt die Produkt-Typen zurück, auf die dieser Addon angewendet werden kann.
  # Immer ein Array, nie nil.
  def applies_to
    Array(effective_attr("applies_to"))
  end

  # Prüft ob dieser Addon auf einen bestimmten Produkttyp anwendbar ist
  def applies_to?(product_type)
    applies_to.include?(product_type.to_s)
  end

  # ── Override-Shortcuts ────────────────────────────────────────────────────

  def override_price_per_location!(value)
    override_attr!("price_per_location", value.to_s)
  end

  # ── Zoho Sync Convenience ─────────────────────────────────────────────────
  def self.sync_from_zoho!(zoho_id:, location:, name:, billing_type:, category:,
                            unit:, applies_to:, price_per_location:,
                            translations: [], raw_payload: {})
    addon = find_or_initialize_by(zoho_product_id: zoho_id)
    addon.location = location

    addon.sync_from_zoho!(
      {
        "name"               => name,
        "billing_type"       => billing_type,
        "category"           => category,
        "unit"               => unit,
        "applies_to"         => Array(applies_to),
        "price_per_location" => price_per_location.to_s
      },
      translations,
      raw_payload
    )
  end
end
