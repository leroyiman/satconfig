class Admin::CitiesController < Admin::BaseController
  before_action :set_city

  def index
    @cities = City.includes(:locations).order(:name)
    render :index
  end

  def show; end

  def update
    incoming = params.dig(:city, :local_attributes) || {}
    current  = (@city.local_attributes || {}).dup

    incoming.each do |key, value|
      value.blank? ? current.delete(key.to_s) : current[key.to_s] = value.strip
    end

    @city.update!(local_attributes: current)
    redirect_to admin_city_path(@city), notice: "Overrides gespeichert."
  end

  def reset_override
    if params[:field].present?
      @city.reset_override!(params[:field])
      redirect_to admin_city_path(@city), notice: "'#{params[:field]}' zurückgesetzt."
    else
      @city.update!(local_attributes: {})
      redirect_to admin_city_path(@city), notice: "Alle Overrides zurückgesetzt."
    end
  end

  private

  def set_city
    @city = City.find(params[:id]) if params[:id]
    @cities = City.includes(:locations).order(:name) if action_name == "index"
  end
end
