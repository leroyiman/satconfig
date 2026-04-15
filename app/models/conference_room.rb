class ConferenceRoom < Product
  # ────────────────────────────────────────────────────────────────────────
  # CRM-Attribute (gespeichert in crm_attributes jsonb):
  #   name, number_of_people, picture_id, price_intern, price_extern
  #
  # Übersetzungen (product_translations):
  #   language, crm_name / local_name
  # ────────────────────────────────────────────────────────────────────────

  # ── Preis-Methoden ────────────────────────────────────────────────────────
  # Gibt immer den effektiven Wert zurück (local override || CRM-Wert)

  def price_intern
    val = effective_attr("price_intern")
    val&.to_d
  end

  def price_extern
    val = effective_attr("price_extern")
    val&.to_d
  end

  # ── Weitere Attribute ─────────────────────────────────────────────────────

  def number_of_people
    effective_attr("number_of_people")&.to_i
  end

  def picture_id
    effective_attr("picture_id")
  end

  # ── Override-Shortcuts ────────────────────────────────────────────────────

  def override_price_intern!(value)
    override_attr!("price_intern", value.to_s)
  end

  def override_price_extern!(value)
    override_attr!("price_extern", value.to_s)
  end

  # ── Zoho Sync Convenience ─────────────────────────────────────────────────
  # Erstellt oder aktualisiert einen Conference Room aus einem Zoho-Payload.
  def self.sync_from_zoho!(zoho_id:, location:, name:, number_of_people:,
                            picture_id:, price_intern:, price_extern:,
                            translations: [], raw_payload: {})
    room = find_or_initialize_by(zoho_product_id: zoho_id)
    room.location = location

    room.sync_from_zoho!(
      {
        "name"             => name,
        "number_of_people" => number_of_people,
        "picture_id"       => picture_id,
        "price_intern"     => price_intern.to_s,
        "price_extern"     => price_extern.to_s
      },
      translations,
      raw_payload
    )
  end
end
