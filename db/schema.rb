# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_04_14_120001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "cities", force: :cascade do |t|
    t.string "zoho_city_id"
    t.string "name", null: false
    t.string "currency", default: "EUR", null: false
    t.boolean "active", default: true, null: false
    t.jsonb "synced_data", default: {}
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_cities_on_active"
    t.index ["name"], name: "index_cities_on_name"
    t.index ["zoho_city_id"], name: "index_cities_on_zoho_city_id", unique: true
  end

  create_table "configuration_addons", force: :cascade do |t|
    t.bigint "configuration_id", null: false
    t.bigint "addon_id", null: false
    t.integer "step", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["addon_id"], name: "index_configuration_addons_on_addon_id"
    t.index ["configuration_id", "addon_id"], name: "index_configuration_addons_on_configuration_id_and_addon_id", unique: true
    t.index ["configuration_id"], name: "index_configuration_addons_on_configuration_id"
    t.index ["step"], name: "index_configuration_addons_on_step"
  end

  create_table "configurations", force: :cascade do |t|
    t.string "share_token", null: false
    t.string "status", default: "draft", null: false
    t.integer "current_step", default: 1, null: false
    t.bigint "location_id"
    t.bigint "product_id"
    t.string "contact_first_name"
    t.string "contact_last_name"
    t.string "contact_company"
    t.string "contact_address"
    t.string "contact_postal_code"
    t.string "contact_city"
    t.string "contact_email"
    t.string "contact_phone"
    t.decimal "total_price", precision: 10, scale: 2, default: "0.0"
    t.string "zoho_lead_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_configurations_on_location_id"
    t.index ["product_id"], name: "index_configurations_on_product_id"
    t.index ["share_token"], name: "index_configurations_on_share_token", unique: true
    t.index ["status"], name: "index_configurations_on_status"
    t.index ["zoho_lead_id"], name: "index_configurations_on_zoho_lead_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "zoho_location_id"
    t.bigint "city_id", null: false
    t.string "name", null: false
    t.text "address"
    t.string "language"
    t.string "picture_id"
    t.string "phone"
    t.string "email"
    t.string "website"
    t.boolean "active", default: true, null: false
    t.jsonb "synced_data", default: {}
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_locations_on_active"
    t.index ["city_id", "active"], name: "index_locations_on_city_id_and_active"
    t.index ["city_id"], name: "index_locations_on_city_id"
    t.index ["zoho_location_id"], name: "index_locations_on_zoho_location_id", unique: true
  end

  create_table "product_translations", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.string "language", null: false
    t.string "crm_name"
    t.text "crm_description"
    t.string "local_name"
    t.text "local_description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["language"], name: "index_product_translations_on_language"
    t.index ["product_id", "language"], name: "index_product_translations_on_product_id_and_language", unique: true
    t.index ["product_id"], name: "index_product_translations_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "type", null: false
    t.string "zoho_product_id"
    t.bigint "location_id", null: false
    t.boolean "active", default: true, null: false
    t.jsonb "crm_attributes", default: {}, null: false
    t.jsonb "local_attributes", default: {}, null: false
    t.jsonb "synced_data", default: {}, null: false
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_products_on_active"
    t.index ["crm_attributes"], name: "index_products_on_crm_attributes", using: :gin
    t.index ["local_attributes"], name: "index_products_on_local_attributes", using: :gin
    t.index ["location_id", "active"], name: "index_products_on_location_id_and_active"
    t.index ["location_id", "type"], name: "index_products_on_location_id_and_type"
    t.index ["location_id"], name: "index_products_on_location_id"
    t.index ["type"], name: "index_products_on_type"
    t.index ["zoho_product_id"], name: "index_products_on_zoho_product_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "configuration_addons", "configurations"
  add_foreign_key "configuration_addons", "products", column: "addon_id"
  add_foreign_key "configurations", "locations"
  add_foreign_key "configurations", "products"
  add_foreign_key "locations", "cities"
  add_foreign_key "product_translations", "products"
  add_foreign_key "products", "locations"
end
