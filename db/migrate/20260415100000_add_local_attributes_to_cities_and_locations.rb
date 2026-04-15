class AddLocalAttributesToCitiesAndLocations < ActiveRecord::Migration[7.1]
  def change
    # Cities: lokale Overrides für name, currency
    add_column :cities, :local_attributes, :jsonb, null: false, default: {}
    add_index  :cities, :local_attributes, using: :gin

    # Locations: lokale Overrides für name, address, description, picture_id,
    #            phone, email, website
    add_column :locations, :local_attributes, :jsonb, null: false, default: {}
    add_index  :locations, :local_attributes, using: :gin
  end
end
