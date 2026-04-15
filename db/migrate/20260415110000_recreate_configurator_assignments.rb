class RecreateConfiguratorAssignments < ActiveRecord::Migration[7.1]
  def change
    drop_table :configurator_assignments

    create_table :configurator_assignments do |t|
      # Pro welche Location gilt diese Zuweisung?
      t.references :location, null: false, foreign_key: true

      # Welches Produkt / Addon wird zugewiesen?
      t.references :product,  null: false, foreign_key: true

      # Welcher Konfigurator: "geschaeftsadresse" | "office" | "meeting"
      t.string  :configurator_type, null: false, default: "geschaeftsadresse"

      # In welchem Step erscheint dieses Produkt? (2–6)
      t.integer :step, null: false

      # Darstellungstyp:
      #   "radio"    → Zeile 1, Single-Select, helle Karte (Hauptprodukt)
      #   "checkbox" → Zeile 2, Multi-Select, Addon-Bereich (erscheint nur wenn vorhanden)
      t.string  :selection_type, null: false, default: "radio"

      # Reihenfolge innerhalb des Steps / der Zeile
      t.integer :position, null: false, default: 0

      t.boolean :active, null: false, default: true

      t.timestamps
    end

    # Ein Produkt kann pro Location+Konfigurator nur einmal zugewiesen sein
    add_index :configurator_assignments,
              [:location_id, :product_id, :configurator_type],
              unique: true,
              name: "idx_conf_assignments_unique"

    add_index :configurator_assignments,
              [:location_id, :configurator_type, :step, :position],
              name: "idx_conf_assignments_lookup"
  end
end
