class Admin::ConfiguratorAssignmentsController < Admin::BaseController
  def index
    @configurator_type = params[:configurator_type] || "geschaeftsadresse"

    # Alle Assignments für diesen Konfigurator
    @assignments = ConfiguratorAssignment
                     .for_configurator(@configurator_type)
                     .includes(:assignable)
                     .ordered

    @location_assignments = @assignments.select { |a| a.assignable_type == "Location" }
    @product_assignments  = @assignments.select { |a| a.assignable_type == "Product" }
                                        .group_by(&:step)

    # Verfügbare Items die noch NICHT zugewiesen sind
    assigned_location_ids = @location_assignments.map(&:assignable_id)
    assigned_product_ids  = @assignments.select { |a| a.assignable_type == "Product" }
                                        .map(&:assignable_id)

    @available_locations = Location.active.includes(:city)
                                   .where.not(id: assigned_location_ids)
                                   .order("cities.name, locations.name")

    # Produkte nach Step-Typ gruppiert (nur relevante Typen je Konfigurator)
    relevant_types = case @configurator_type
                     when "geschaeftsadresse" then %w[VirtualOffice CompanyHeadquarter Addon]
                     when "office"            then %w[Office Addon]
                     when "meeting"           then %w[ConferenceRoom Addon]
                     end

    @available_products = Product.active
                                 .where(type: relevant_types)
                                 .where.not(id: assigned_product_ids)
                                 .includes(:location)
                                 .order(:type, Arel.sql("crm_attributes->>'name'"))
                                 .group_by(&:type)
  end

  def create
    assignment = ConfiguratorAssignment.new(
      configurator_type: params[:configurator_type] || "geschaeftsadresse",
      assignable_type:   params[:assignable_type],
      assignable_id:     params[:assignable_id],
      step:              params[:step].presence&.to_i,
      position:          params[:position].to_i
    )

    if assignment.save
      redirect_to admin_configurator_assignments_path(configurator_type: assignment.configurator_type),
                  notice: "Erfolgreich zugewiesen."
    else
      redirect_to admin_configurator_assignments_path(configurator_type: assignment.configurator_type),
                  alert: assignment.errors.full_messages.join(", ")
    end
  end

  def destroy
    assignment = ConfiguratorAssignment.find(params[:id])
    conf_type  = assignment.configurator_type
    assignment.destroy!
    redirect_to admin_configurator_assignments_path(configurator_type: conf_type),
                notice: "Zuweisung entfernt."
  end
end
