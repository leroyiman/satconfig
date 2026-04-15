class CreateCities < ActiveRecord::Migration[7.1]
  def change
    create_table :cities do |t|
      t.string  :zoho_city_id
      t.string  :name,       null: false
      t.string  :currency,   null: false, default: "EUR"
      t.boolean :active,     null: false, default: true
      t.jsonb   :synced_data,             default: {}
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :cities, :zoho_city_id, unique: true
    add_index :cities, :name
    add_index :cities, :active
  end
end
