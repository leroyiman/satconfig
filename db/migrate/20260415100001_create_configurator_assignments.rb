class CreateConfiguratorAssignments < ActiveRecord::Migration[7.1]
  def change
    create_table :configurator_assignments do |t|
      # Welcher Konfigurator: "geschaeftsadresse" | "office" | "meeting"
      t.string  :configurator_type, null: false

      # Polymorphisch: "Product" oder "Location"
      t.string  :assignable_type,   null: false
      t.bigint  :assignable_id,     null: false

      # In welchem Step soll das Item erscheinen?
      # nil = Step wird aus dem Typ abgeleitet (Locations → Step 1, etc.)
      t.integer :step

      # Reihenfolge innerhalb des Steps
      t.integer :position, null: false, default: 0

      t.boolean :active, null: false, default: true

      t.timestamps
    end

    # Ein Item kann pro Konfigurator nur einmal zugewiesen werden
    add_index :configurator_assignments,
              [:configurator_type, :assignable_type, :assignable_id],
              unique: true,
              name: "idx_configurator_assignments_unique"

    add_index :configurator_assignments, [:configurator_type, :step, :position]
    add_index :configurator_assignments, [:assignable_type, :assignable_id]
  end
end
