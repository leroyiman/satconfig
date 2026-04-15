class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      # STI – Typ-Spalte: ConferenceRoom | Office | VirtualOffice | CompanyHeadquarter | Addon
      t.string :type, null: false

      t.string     :zoho_product_id
      t.references :location, null: false, foreign_key: true

      t.boolean :active, null: false, default: true

      # ── CRM-Daten (von Zoho, werden bei jedem Sync überschrieben) ────────────
      # Enthält typ-spezifische Felder, z.B.:
      #   ConferenceRoom: { number_of_people:, picture_id:, price_intern:, price_extern: }
      #   Office:         { square_meters:, workspaces:, floor:, floor_plan_image_id:, price_3:, price_12: }
      #   VirtualOffice:  { price_3:, price_12: }
      #   CompanyHQ:      { price_3:, price_12: }
      #   Addon:          { billing_type:, category:, unit:, applies_to:[], price_per_location: }
      t.jsonb :crm_attributes, null: false, default: {}

      # ── App-seitige Overrides (werden NIE durch den Sync überschrieben) ──────
      # Nur die tatsächlich überschriebenen Keys sind vorhanden.
      # effective_attr(key) = local_attributes[key] || crm_attributes[key]
      t.jsonb :local_attributes, null: false, default: {}

      # Kompletter Raw-Payload von Zoho zur Nachverfolgung
      t.jsonb    :synced_data, null: false, default: {}
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :products, :zoho_product_id, unique: true
    add_index :products, :type
    add_index :products, :active
    add_index :products, [:location_id, :type]
    add_index :products, [:location_id, :active]

    # GIN-Index für effiziente jsonb-Suchen
    add_index :products, :crm_attributes,   using: :gin
    add_index :products, :local_attributes, using: :gin
  end
end
