module Api
  module V1
    module Zoho
      class WebhookController < ApplicationController
        # Kein CSRF-Schutz für externe API-Aufrufe
        skip_before_action :verify_authenticity_token

        # Devise: kein Login erforderlich – Auth läuft über Bearer Token
        skip_before_action :authenticate_user!, raise: false

        # Signatur wird vor jeder Aktion geprüft
        before_action :verify_bearer_token!

        # POST /api/v1/zoho/webhook
        def receive
          result = ::Zoho::WebhookProcessor.new(payload).call

          if result.success?
            render json: { status: "accepted", event: payload["event"] }, status: :accepted
          else
            Rails.logger.error("[ZohoWebhook] Processing error: #{result.error}")
            render json: { error: result.error }, status: :unprocessable_entity
          end
        rescue JSON::ParserError => e
          Rails.logger.error("[ZohoWebhook] Invalid JSON: #{e.message}")
          render json: { error: "Invalid JSON payload" }, status: :bad_request
        rescue => e
          Rails.logger.error("[ZohoWebhook] Unexpected error: #{e.class} – #{e.message}")
          Rails.logger.error(e.backtrace.first(5).join("\n"))
          render json: { error: "Internal server error" }, status: :internal_server_error
        end

        private

        # ── Bearer Token Verifikation ──────────────────────────────────────────
        # Zoho muss folgenden Header mitsenden:
        #   Authorization: Bearer <ZOHO_WEBHOOK_SECRET>
        #
        # Das Secret wird in Rails Credentials gespeichert:
        #   rails credentials:edit
        #   zoho_webhook_secret: <dein-secret>
        #
        # Oder alternativ als ENV-Variable: ZOHO_WEBHOOK_SECRET
        def verify_bearer_token!
          provided_token = extract_bearer_token
          expected_token = webhook_secret

          if expected_token.blank?
            Rails.logger.error("[ZohoWebhook] ZOHO_WEBHOOK_SECRET ist nicht konfiguriert!")
            render json: { error: "Server misconfiguration" }, status: :internal_server_error
            return
          end

          # secure_compare verhindert Timing-Attacks
          unless provided_token.present? &&
                 ActiveSupport::SecurityUtils.secure_compare(provided_token, expected_token)
            Rails.logger.warn("[ZohoWebhook] Unauthorized request – falsche oder fehlende Credentials. IP: #{request.remote_ip}")
            render json: { error: "Unauthorized" }, status: :unauthorized
          end
        end

        def extract_bearer_token
          auth_header = request.headers["Authorization"]
          return nil unless auth_header&.start_with?("Bearer ")

          auth_header.sub("Bearer ", "").strip
        end

        def webhook_secret
          ENV["ZOHO_WEBHOOK_SECRET"].presence ||
            Rails.application.credentials.dig(:zoho, :webhook_secret).to_s
        end

        # ── Payload ───────────────────────────────────────────────────────────
        # Parst den raw JSON Body einmalig und cached das Ergebnis.
        def payload
          @payload ||= JSON.parse(request.raw_post)
        end
      end
    end
  end
end
