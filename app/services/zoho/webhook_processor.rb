module Zoho
  # Hauptverarbeiter für eingehende Zoho-Webhooks.
  # Liest event + entity_type und delegiert an den passenden Sub-Service.
  #
  # Aufgerufen vom Api::V1::Zoho::WebhookController.
  class WebhookProcessor
    ENTITY_HANDLERS = {
      "city"                  => "Zoho::SyncCityService",
      "location"              => "Zoho::SyncLocationService",
      "conference_room"       => "Zoho::SyncProductService",
      "office"                => "Zoho::SyncProductService",
      "virtual_office"        => "Zoho::SyncProductService",
      "company_headquarter"   => "Zoho::SyncProductService",
      "addon"                 => "Zoho::SyncProductService"
    }.freeze

    def initialize(payload)
      @payload     = payload
      @event       = payload["event"].to_s
      @entity_type = payload["entity_type"].to_s
      @zoho_id     = payload["zoho_id"].to_s
      @data        = payload["data"] || {}
    end

    def call
      Rails.logger.info("[ZohoWebhook] Event: #{@event} | Entity: #{@entity_type} | ID: #{@zoho_id}")

      return Result.fail("Missing event") if @event.blank?
      return Result.fail("Missing entity_type") if @entity_type.blank?
      return Result.fail("Missing zoho_id") if @zoho_id.blank?

      handler_class = ENTITY_HANDLERS[@entity_type]
      return Result.fail("Unknown entity_type: '#{@entity_type}'") if handler_class.nil?

      handler_class.constantize.new(
        event:       @event,
        entity_type: @entity_type,
        zoho_id:     @zoho_id,
        data:        @data,
        raw_payload: @payload
      ).call
    rescue => e
      Rails.logger.error("[ZohoWebhook] #{e.class}: #{e.message}")
      Result.fail("#{e.class}: #{e.message}")
    end
  end
end
