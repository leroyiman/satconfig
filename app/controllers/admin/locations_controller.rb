class Admin::LocationsController < Admin::BaseController
  before_action :set_location, only: [:show, :update, :reset_override]

  def index
    @cities    = City.active.includes(:locations).order(:name)
    @locations = Location.active.includes(:city).order("cities.name, locations.name")
    @locations = @locations.where(city: City.find(params[:city_id])) if params[:city_id].present?
  end

  def show
    @products_by_type = @location.products.active.group_by(&:type)
  end

  def update
    incoming = params.dig(:location, :local_attributes) || {}
    current  = (@location.local_attributes || {}).dup

    incoming.each do |key, value|
      value.blank? ? current.delete(key.to_s) : current[key.to_s] = value.strip
    end

    @location.update!(local_attributes: current)
    redirect_to admin_location_path(@location), notice: "Overrides gespeichert."
  end

  def reset_override
    if params[:field].present?
      @location.reset_override!(params[:field])
      redirect_to admin_location_path(@location), notice: "'#{params[:field]}' zurückgesetzt."
    else
      @location.reset_all_overrides!
      redirect_to admin_location_path(@location), notice: "Alle Overrides zurückgesetzt."
    end
  end

  private

  def set_location
    @location = Location.includes(:city, :products).find(params[:id])
  end
end
