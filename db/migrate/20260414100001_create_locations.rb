class CreateLocations < ActiveRecord::Migration[7.1]
  def change
    create_table :locations do |t|
      t.string  :zoho_location_id
      t.references :city, null: false, foreign_key: true

      t.string  :name,       null: false
      t.text    :address
      t.string  :language               # Standard-Sprache der Location (z.B. "de", "en")
      t.string  :picture_id             # Zoho Bild-Referenz
      t.string  :phone
      t.string  :email
      t.string  :website

      t.boolean :active,     null: false, default: true
      t.jsonb   :synced_data,             default: {}
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :locations, :zoho_location_id, unique: true
    add_index :locations, :active
    add_index :locations, [:city_id, :active]
  end
end
