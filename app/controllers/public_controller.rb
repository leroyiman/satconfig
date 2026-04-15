# Basis-Controller für alle öffentlichen Seiten (kein Login erforderlich).
class PublicController < ApplicationController
  skip_before_action :authenticate_user!
end
