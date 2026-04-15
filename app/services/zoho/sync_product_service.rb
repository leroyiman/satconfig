module Zoho
  # Verarbeitet alle Produkt-Events für alle 5 Typen:
  #   conference_room, office, virtual_office, company_headquarter, addon
  #
  # WICHTIG: local_attributes werden NIE angefasst.
  # Nur crm_attributes und product_translations (crm_*-Felder) werden aktualisiert.
  class SyncProductService
    ENTITY_TYPE_TO_CLASS = {
      "conference_room"     => "ConferenceRoom",
      "office"              => "Office",
      "virtual_office"      => "VirtualOffice",
      "company_headquarter" => "CompanyHeadquarter",
      "addon"               => "Addon"
    }.freeze

    def initialize(event:, entity_type:, zoho_id:, data:, raw_payload:)
      @event       = event
      @entity_type = entity_type
      @zoho_id     = zoho_id
      @data        = data
      @raw_payload = raw_payload
    end

    def call
      action = @event.split(".").last  # "created" / "updated" / "deleted"

      case action
      when "created", "updated"
        upsert_product
      when "deleted"
        deactivate_product
      else
        Result.fail("Unbekannte Aktion im Event: #{@event}")
      end
    end

    private

    # ── Upsert ────────────────────────────────────────────────────────────────

    def upsert_product
      return Result.fail("location_zoho_id fehlt") if @data["location_zoho_id"].blank?

      location = Location.find_by(zoho_location_id: @data["location_zoho_id"])
      return Result.fail("Location nicht gefunden: #{@data["location_zoho_id"]}") unless location

      product_class_name = ENTITY_TYPE_TO_CLASS[@entity_type]
      return Result.fail("Unbekannter entity_type: #{@entity_type}") unless product_class_name

      product_class = product_class_name.constantize
      product = product_class.find_or_initialize_by(zoho_product_id: @zoho_id)
      product.location = location
      product.active   = true

      # Typ-spezifische CRM-Attribute aufbauen
      product.crm_attributes  = build_crm_attributes
      product.synced_data     = @raw_payload
      product.last_synced_at  = Time.current
      product.save!

      # Übersetzungen synchronisieren (nur crm_*-Felder, local_* bleiben erhalten)
      sync_translations(product)

      Rails.logger.info("[ZohoWebhook] #{product_class_name} #{@event.split('.').last}: #{product.effective_attr('name')} (#{@zoho_id})")
      Result.ok(product)
    rescue ActiveRecord::RecordInvalid => e
      Result.fail("Produkt konnte nicht gespeichert werden: #{e.message}")
    end

    # ── Delete ────────────────────────────────────────────────────────────────

    def deactivate_product
      product = Product.find_by(zoho_product_id: @zoho_id)
      if product
        product.update!(active: false, last_synced_at: Time.current)
        Rails.logger.info("[ZohoWebhook] Produkt deaktiviert: #{@zoho_id}")
        Result.ok(product)
      else
        Rails.logger.warn("[ZohoWebhook] Produkt nicht gefunden für Delete: #{@zoho_id}")
        Result.ok
      end
    end

    # ── CRM-Attribute je Typ ──────────────────────────────────────────────────

    def build_crm_attributes
      base = { "name" => @data["name"] }

      case @entity_type
      when "conference_room"
        base.merge(
          "number_of_people" => @data["number_of_people"],
          "picture_id"       => @data["picture_id"],
          "price_intern"     => @data["price_intern"],
          "price_extern"     => @data["price_extern"]
        )
      when "office"
        base.merge(
          "square_meters"       => @data["square_meters"],
          "workspaces"          => @data["workspaces"],
          "floor"               => @data["floor"],
          "floor_plan_image_id" => @data["floor_plan_image_id"],
          "price_3"             => @data["price_3"],
          "price_12"            => @data["price_12"]
        )
      when "virtual_office", "company_headquarter"
        base.merge(
          "price_3"  => @data["price_3"],
          "price_12" => @data["price_12"]
        )
      when "addon"
        base.merge(
          "billing_type"       => @data["billing_type"],
          "category"           => @data["category"],
          "unit"               => @data["unit"],
          "applies_to"         => Array(@data["applies_to"]),
          "price_per_location" => @data["price_per_location"]
        )
      else
        base
      end.compact
    end

    # ── Übersetzungen ─────────────────────────────────────────────────────────
    # Nur crm_name und crm_description werden geschrieben.
    # local_name / local_description bleiben unangetastet.

    def sync_translations(product)
      translations = Array(@data["translations"])
      return if translations.empty?

      translations.each do |t|
        language = t["language"].to_s
        next if language.blank?

        trans = product.product_translations.find_or_initialize_by(language: language)
        trans.crm_name        = t["name"]
        trans.crm_description = t["description"]
        trans.save!
      end
    end
  end
end
