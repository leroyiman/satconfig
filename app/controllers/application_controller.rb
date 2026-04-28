class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  # Devise-Login-Seite (sessions#new) bekommt das eigene Auth-Layout
  # mit dem conf-hero Header. Andere Devise-Aktionen bleiben unverändert.
  layout :resolve_layout

  private

  def resolve_layout
    if devise_controller? && controller_name == "sessions" && action_name == "new"
      "auth"
    else
      "application"
    end
  end
end
