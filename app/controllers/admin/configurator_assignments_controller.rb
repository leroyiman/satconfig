class Admin::ConfiguratorAssignmentsController < Admin::BaseController
  before_action :set_location, only: [:index]

  def index
    @configurator_type = params[:configurator_type] || "geschaeftsadresse"
    @locations         = Location.active.includes(:city).order("locations.name")

    return unless @location

    # Alle Zuweisungen dieser Location für diesen Konfigurator, nach Step gruppiert
    all = ConfiguratorAssignment
            .where(location: @location, configurator_type: @configurator_type)
            .active
            .ordered
            .includes(:product)

    @assignments_by_step = all.group_by(&:step)

    # Alle Produkte dieser Location die noch nicht zugewiesen sind
    assigned_product_ids = all.map(&:product_id)
    @available_products  = @location.products
                                    .active
                                    .where.not(id: assigned_product_ids)
                                    .order(:type, Arel.sql("crm_attributes->>'name'"))
                                    .group_by(&:type)
  end

  def create
    location = Location.find(params[:location_id])
    product  = Product.find(params[:product_id])

    assignment = ConfiguratorAssignment.new(
      location:          location,
      product:           product,
      configurator_type: params[:configurator_type] || "geschaeftsadresse",
      step:              params[:step].to_i,
      selection_type:    params[:selection_type] || "radio",
      position:          params[:position].to_i
    )

    if assignment.save
      redirect_to admin_configurator_assignments_path(
                    location_id: location.id,
                    configurator_type: assignment.configurator_type
                  ), notice: "Produkt zugewiesen."
    else
      redirect_to admin_configurator_assignments_path(
                    location_id: location.id,
                    configurator_type: params[:configurator_type]
                  ), alert: assignment.errors.full_messages.join(", ")
    end
  end

  def destroy
    assignment = ConfiguratorAssignment.find(params[:id])
    location   = assignment.location
    conf_type  = assignment.configurator_type
    assignment.destroy!
    redirect_to admin_configurator_assignments_path(
                  location_id: location.id,
                  configurator_type: conf_type
                ), notice: "Zuweisung entfernt."
  end

  private

  def set_location
    @location = Location.find(params[:location_id]) if params[:location_id].present?
  end
end
