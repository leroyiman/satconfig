module Zoho
  # Verarbeitet location.created, location.updated und location.deleted Events.
  class SyncLocationService
    def initialize(event:, entity_type:, zoho_id:, data:, raw_payload:)
      @event       = event
      @zoho_id     = zoho_id
      @data        = data
      @raw_payload = raw_payload
    end

    def call
      case @event
      when "location.created", "location.updated"
        upsert_location
      when "location.deleted"
        deactivate_location
      else
        Result.fail("Unbekannter Location-Event: #{@event}")
      end
    end

    private

    def upsert_location
      return Result.fail("name fehlt") if @data["name"].blank?
      return Result.fail("city_zoho_id fehlt") if @data["city_zoho_id"].blank?

      city = City.find_by(zoho_city_id: @data["city_zoho_id"])
      return Result.fail("Stadt nicht gefunden: #{@data["city_zoho_id"]}") unless city

      location = Location.find_or_initialize_by(zoho_location_id: @zoho_id)
      location.assign_attributes(
        city:           city,
        name:           @data["name"],
        address:        @data["address"],
        language:       @data["language"],
        picture_id:     @data["picture_id"],
        phone:          @data["phone"],
        email:          @data["email"],
        website:        @data["website"],
        active:         true,
        synced_data:    @raw_payload,
        last_synced_at: Time.current
      )
      location.save!
      Rails.logger.info("[ZohoWebhook] Location #{@event}: #{location.name} (#{@zoho_id})")
      Result.ok(location)
    rescue ActiveRecord::RecordInvalid => e
      Result.fail("Location konnte nicht gespeichert werden: #{e.message}")
    end

    def deactivate_location
      location = Location.find_by(zoho_location_id: @zoho_id)
      if location
        location.update!(active: false, last_synced_at: Time.current)
        Rails.logger.info("[ZohoWebhook] Location deaktiviert: #{@zoho_id}")
        Result.ok(location)
      else
        Rails.logger.warn("[ZohoWebhook] Location nicht gefunden für Delete: #{@zoho_id}")
        Result.ok
      end
    end
  end
end
