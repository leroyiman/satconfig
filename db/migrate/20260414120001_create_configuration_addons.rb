class CreateConfigurationAddons < ActiveRecord::Migration[7.1]
  def change
    create_table :configuration_addons do |t|
      t.references :configuration, null: false, foreign_key: true
      t.references :addon,         null: false, foreign_key: { to_table: :products }

      # In welchem Step wurde dieser Addon gewählt?
      # 3 = Erreichbarkeit, 4 = Meetings, 5 = Membership, 6 = Upgrade
      t.integer :step, null: false

      t.timestamps
    end

    # Ein Addon kann pro Konfiguration nur einmal ausgewählt werden
    add_index :configuration_addons, [:configuration_id, :addon_id], unique: true
    add_index :configuration_addons, :step
  end
end
