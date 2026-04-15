class Office < Product
  # ────────────────────────────────────────────────────────────────────────
  # CRM-Attribute (gespeichert in crm_attributes jsonb):
  #   name, square_meters, workspaces, floor, floor_plan_image_id,
  #   price_3, price_12
  #
  # Übersetzungen (product_translations):
  #   language, crm_name / local_name, crm_description / local_description
  #   (description kann HTML/ul-Code enthalten)
  # ────────────────────────────────────────────────────────────────────────

  # ── Preis-Methoden ────────────────────────────────────────────────────────

  def price_3
    effective_attr("price_3")&.to_d
  end

  def price_12
    effective_attr("price_12")&.to_d
  end

  # ── Weitere Attribute ─────────────────────────────────────────────────────

  def square_meters
    effective_attr("square_meters")&.to_i
  end

  def workspaces
    effective_attr("workspaces")&.to_i
  end

  def floor
    effective_attr("floor")
  end

  def floor_plan_image_id
    effective_attr("floor_plan_image_id")
  end

  # ── Override-Shortcuts ────────────────────────────────────────────────────

  def override_price_3!(value)
    override_attr!("price_3", value.to_s)
  end

  def override_price_12!(value)
    override_attr!("price_12", value.to_s)
  end

  # ── Zoho Sync Convenience ─────────────────────────────────────────────────
  def self.sync_from_zoho!(zoho_id:, location:, name:, square_meters:,
                            workspaces:, floor:, floor_plan_image_id:,
                            price_3:, price_12:, translations: [], raw_payload: {})
    office = find_or_initialize_by(zoho_product_id: zoho_id)
    office.location = location

    office.sync_from_zoho!(
      {
        "name"                => name,
        "square_meters"       => square_meters.to_s,
        "workspaces"          => workspaces.to_s,
        "floor"               => floor,
        "floor_plan_image_id" => floor_plan_image_id,
        "price_3"             => price_3.to_s,
        "price_12"            => price_12.to_s
      },
      translations,
      raw_payload
    )
  end
end
