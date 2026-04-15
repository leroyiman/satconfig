module Zoho
  # Verarbeitet city.created, city.updated und city.deleted Events.
  class SyncCityService
    def initialize(event:, entity_type:, zoho_id:, data:, raw_payload:)
      @event       = event
      @zoho_id     = zoho_id
      @data        = data
      @raw_payload = raw_payload
    end

    def call
      case @event
      when "city.created", "city.updated"
        upsert_city
      when "city.deleted"
        deactivate_city
      else
        Result.fail("Unbekannter City-Event: #{@event}")
      end
    end

    private

    def upsert_city
      return Result.fail("name fehlt") if @data["name"].blank?
      return Result.fail("currency fehlt") if @data["currency"].blank?

      city = City.find_or_initialize_by(zoho_city_id: @zoho_id)
      city.assign_attributes(
        name:           @data["name"],
        currency:       @data["currency"],
        active:         true,
        synced_data:    @raw_payload,
        last_synced_at: Time.current
      )
      city.save!
      Rails.logger.info("[ZohoWebhook] City #{@event}: #{city.name} (#{@zoho_id})")
      Result.ok(city)
    rescue ActiveRecord::RecordInvalid => e
      Result.fail("City konnte nicht gespeichert werden: #{e.message}")
    end

    def deactivate_city
      city = City.find_by(zoho_city_id: @zoho_id)
      if city
        city.update!(active: false, last_synced_at: Time.current)
        Rails.logger.info("[ZohoWebhook] City deaktiviert: #{@zoho_id}")
        Result.ok(city)
      else
        Rails.logger.warn("[ZohoWebhook] City nicht gefunden für Delete: #{@zoho_id}")
        Result.ok  # Kein Fehler – idempotent
      end
    end
  end
end
