Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  # ── Zoho CRM Webhook ──────────────────────────────────────────────────────
  # POST /api/v1/zoho/webhook
  # Empfängt Push-Notifications von Zoho bei Änderungen an Cities, Locations
  # und Produkten (Conference Rooms, Offices, Virtual Offices, HQ, Addons).
  # Authentifizierung via Bearer Token (Authorization Header).
  namespace :api do
    namespace :v1 do
      namespace :zoho do
        post :webhook, to: "webhook#receive"
      end
    end
  end

  # ── Konfigurator (öffentlich, kein Login) ────────────────────────────────
  scope "/konfigurator", as: :configurator do
    get  "/",                              to: "configurator#new",       as: ""
    post "/",                              to: "configurator#create"
    get  "/:token/schritt/:step",          to: "configurator#show",      as: :step
    patch "/:token/schritt/:step",         to: "configurator#update"
    get  "/:token/danke",                  to: "configurator#submitted", as: :submitted
  end

  # ── Admin ─────────────────────────────────────────────────────────────────
  namespace :admin do
    root to: "dashboard#index"

    resources :locations, only: [:index, :show]

    resources :products, only: [:index, :show, :update] do
      member do
        patch :reset_override        # ?field=price_3 → einzelnes Feld zurücksetzen
                                     # kein ?field   → alle Overrides zurücksetzen
      end
    end

    resources :product_translations, only: [:update] do
      member do
        patch :reset_override        # ?field=name|description|all
      end
    end
  end

  # ── Health Check ──────────────────────────────────────────────────────────
  get "up" => "rails/health#show", as: :rails_health_check
end
