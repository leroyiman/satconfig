class CreateProductTranslations < ActiveRecord::Migration[7.1]
  def change
    create_table :product_translations do |t|
      t.references :product, null: false, foreign_key: true
      t.string     :language, null: false   # z.B. "de", "en", "fr", "es"

      # ── CRM-Werte (direkt von Zoho) ──────────────────────────────────────────
      t.string :crm_name
      t.text   :crm_description             # Kann HTML/ul-Code enthalten

      # ── App-seitige Overrides ────────────────────────────────────────────────
      # Wenn gesetzt, überschreiben diese den CRM-Wert in der Darstellung.
      # Beide Werte bleiben erhalten – effective_name gibt den richtigen zurück.
      t.string :local_name
      t.text   :local_description

      t.timestamps
    end

    # Ein Produkt hat pro Sprache genau eine Übersetzung
    add_index :product_translations, [:product_id, :language], unique: true
    add_index :product_translations, :language
  end
end
