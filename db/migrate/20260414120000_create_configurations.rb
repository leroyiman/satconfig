class CreateConfigurations < ActiveRecord::Migration[7.1]
  def change
    create_table :configurations do |t|
      # ── Identifikation ──────────────────────────────────────────────────────
      t.string  :share_token, null: false           # URL-Token (kein Login nötig)
      t.string  :status,      null: false, default: "draft"  # draft | submitted
      t.integer :current_step, null: false, default: 1

      # ── Step 1: Location ────────────────────────────────────────────────────
      t.references :location, foreign_key: true

      # ── Step 2: Hauptprodukt (VirtualOffice oder CompanyHeadquarter) ────────
      t.references :product, foreign_key: true

      # ── Step 7: Kontaktdaten ────────────────────────────────────────────────
      t.string :contact_first_name
      t.string :contact_last_name
      t.string :contact_company
      t.string :contact_address
      t.string :contact_postal_code
      t.string :contact_city
      t.string :contact_email
      t.string :contact_phone

      # ── Berechneter Gesamtpreis ─────────────────────────────────────────────
      t.decimal :total_price, precision: 10, scale: 2, default: 0

      # ── Zoho Lead Rücksync ──────────────────────────────────────────────────
      t.string :zoho_lead_id

      t.timestamps
    end

    add_index :configurations, :share_token, unique: true
    add_index :configurations, :status
    add_index :configurations, :zoho_lead_id
  end
end
