class Admin::LocationsController < Admin::BaseController
  def index
    @cities    = City.active.includes(:locations).order(:name)
    @locations = Location.active.includes(:city).order("cities.name, locations.name")
    @locations = @locations.where(city: City.find(params[:city_id])) if params[:city_id].present?
  end

  def show
    @location = Location.includes(:city, :products).find(params[:id])
    @products_by_type = @location.products.active.group_by(&:type)
  end
end
