class Addon < Product
  # ────────────────────────────────────────────────────────────────────────
  # CRM-Attribute (gespeichert in crm_attributes jsonb):
  #   name, billing_type, category, unit, applies_to (Array), price_per_location
  #
  # applies_to: Array mit Produkt-Typ-Strings, z.B.:
  #   ["Office", "VirtualOffice", "CompanyHeadquarter", "ConferenceRoom"]
  #
  # Pro-Location-Preise werden von Zoho in synced_data["data"]["prices"] geliefert:
  #   [{ "price" => "1.55", "location_zoho_id" => "226273000000051033" }, ...]
  #
  # Lokale Overrides pro Location liegen in local_attributes["prices_by_location"]:
  #   { "226273000000051033" => "1.60", ... }
  #
  # Übersetzungen (product_translations):
  #   language, crm_name / local_name, crm_description / local_description
  # ────────────────────────────────────────────────────────────────────────

  VALID_BILLING_TYPES = %w[monthly one_time per_use yearly].freeze
  VALID_APPLIES_TO    = %w[ConferenceRoom Office VirtualOffice CompanyHeadquarter].freeze

  PRICES_BY_LOCATION_KEY = "prices_by_location".freeze

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

  # ── Per-Location-Preise ───────────────────────────────────────────────────

  # Rohes Array aus synced_data (Quelle der Wahrheit aus Zoho)
  #   [{ "price" => "1.55", "location_zoho_id" => "226273000000051033" }, ...]
  def crm_price_entries
    Array(synced_data&.dig("data", "prices"))
  end

  # Lokale Overrides pro Location ({ zoho_location_id => price_string })
  def local_prices_by_location
    (local_attributes || {})[PRICES_BY_LOCATION_KEY] || {}
  end

  # CRM-Preis für eine einzelne Location (als BigDecimal oder nil)
  def crm_price_for_location(zoho_location_id)
    entry = crm_price_entries.find do |e|
      e["location_zoho_id"].to_s == zoho_location_id.to_s
    end
    entry && entry["price"].to_d
  end

  # Lokaler Override-Preis für eine einzelne Location (als BigDecimal oder nil)
  def local_price_for_location(zoho_location_id)
    val = local_prices_by_location[zoho_location_id.to_s]
    val.present? ? val.to_d : nil
  end

  # Effektiver Preis für eine Location: local > crm
  def effective_price_for_location(zoho_location_id)
    local_price_for_location(zoho_location_id) || crm_price_for_location(zoho_location_id)
  end

  def price_overridden_for_location?(zoho_location_id)
    local_prices_by_location.key?(zoho_location_id.to_s)
  end

  # Aufbereitete Zeilen-Daten für die Admin-UI – eine Zeile pro Location
  #   [{ location_zoho_id:, location: <Location|nil>, crm_price:, local_price:,
  #      effective_price:, overridden?: }, ...]
  def location_price_rows
    # Alle zoho_location_ids aus CRM-Daten + eventuell aus lokalen Overrides
    ids = crm_price_entries.map { |e| e["location_zoho_id"].to_s }
    ids += local_prices_by_location.keys.map(&:to_s)
    ids = ids.uniq

    locations_by_zoho_id = Location
      .where(zoho_location_id: ids)
      .includes(:city)
      .index_by { |l| l.zoho_location_id.to_s }

    ids.map do |zid|
      {
        location_zoho_id: zid,
        location:         locations_by_zoho_id[zid],
        crm_price:        crm_price_for_location(zid),
        local_price:      local_price_for_location(zid),
        effective_price:  effective_price_for_location(zid),
        overridden?:      price_overridden_for_location?(zid)
      }
    end.sort_by do |row|
      loc = row[:location]
      [loc ? 0 : 1, loc&.city&.name.to_s, loc&.name.to_s, row[:location_zoho_id]]
    end
  end

  # ── Override-Shortcuts ────────────────────────────────────────────────────

  def override_price_per_location!(value)
    override_attr!("price_per_location", value.to_s)
  end

  # Setzt einen Override für eine einzelne Location
  def override_price_for_location!(zoho_location_id, value)
    map = local_prices_by_location.dup
    map[zoho_location_id.to_s] = value.to_s.strip
    self.local_attributes = (local_attributes || {}).merge(PRICES_BY_LOCATION_KEY => map)
    save!
  end

  # Entfernt den Override für eine einzelne Location
  def reset_price_for_location!(zoho_location_id)
    map = local_prices_by_location.dup
    map.delete(zoho_location_id.to_s)
    new_locals = (local_attributes || {}).dup
    if map.empty?
      new_locals.delete(PRICES_BY_LOCATION_KEY)
    else
      new_locals[PRICES_BY_LOCATION_KEY] = map
    end
    self.local_attributes = new_locals
    save!
  end

  # Entfernt alle Per-Location-Overrides auf einmal
  def reset_all_location_price_overrides!
    new_locals = (local_attributes || {}).dup
    new_locals.delete(PRICES_BY_LOCATION_KEY)
    update!(local_attributes: new_locals)
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
