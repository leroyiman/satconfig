class CompanyHeadquarter < Product
  # ────────────────────────────────────────────────────────────────────────
  # CRM-Attribute (gespeichert in crm_attributes jsonb):
  #   name, price_3, price_12
  #
  # Übersetzungen (product_translations):
  #   language, crm_name / local_name, crm_description / local_description
  # ────────────────────────────────────────────────────────────────────────

  # ── Preis-Methoden ────────────────────────────────────────────────────────

  def price_3
    effective_attr("price_3")&.to_d
  end

  def price_12
    effective_attr("price_12")&.to_d
  end

  # ── Override-Shortcuts ────────────────────────────────────────────────────

  def override_price_3!(value)
    override_attr!("price_3", value.to_s)
  end

  def override_price_12!(value)
    override_attr!("price_12", value.to_s)
  end

  # ── Zoho Sync Convenience ─────────────────────────────────────────────────
  def self.sync_from_zoho!(zoho_id:, location:, name:, price_3:, price_12:,
                            translations: [], raw_payload: {})
    hq = find_or_initialize_by(zoho_product_id: zoho_id)
    hq.location = location

    hq.sync_from_zoho!(
      {
        "name"     => name,
        "price_3"  => price_3.to_s,
        "price_12" => price_12.to_s
      },
      translations,
      raw_payload
    )
  end
end
