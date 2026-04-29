class Admin::ConfiguratorAssignmentsController < Admin::BaseController
  before_action :set_location, only: [:index]

  def index
    @configurator_type = params[:configurator_type] || "geschaeftsadresse"
    # Sortierung passt zum Display-Format "Stadt – Standort": erst nach
    # Stadt, dann nach effective_name (berücksichtigt lokale Overrides),
    # beides case-insensitive. Daher Ruby-Sort statt SQL-ORDER.
    @locations         = Location.active
                                  .includes(:city)
                                  .to_a
                                  .sort_by { |l| [l.city.name.to_s.downcase, l.effective_name.to_s.downcase] }

    return unless @location

    # Alle Zuweisungen dieser Location für diesen Konfigurator, nach Step gruppiert
    all = ConfiguratorAssignment
            .where(location: @location, configurator_type: @configurator_type)
            .active
            .ordered
            .includes(:product)

    @assignments_by_step = all.group_by(&:step)

    # Alle Produkte die für die Auswahl in Frage kommen.
    #
    # Wichtig: Addons werden NICHT über @location.products gefiltert!
    # Zoho liefert pro Addon einen einzigen Datensatz mit n Preisen
    # (eine pro Location). Das belongs_to :location auf einem Addon
    # zeigt daher nur auf eine arbiträre "Erst-Location" und ist als
    # Verfügbarkeits-Indikator unbrauchbar. Die Wahrheit steckt im
    # synced_data["data"]["prices"]-Array.
    assigned_product_ids = all.map(&:product_id)

    # 1) Echte Location-Produkte (Office, ConferenceRoom, ...) — bleiben
    #    standortgebunden über belongs_to :location.
    location_scoped = @location.products
                               .active
                               .where.not(type: "Addon")
                               .where.not(id: assigned_product_ids)
                               .to_a

    # 2) Addons — alle aktiven Addons, die einen Preis (CRM oder lokal)
    #    für diese Location haben.
    addons_for_location = Addon.active
                               .where.not(id: assigned_product_ids)
                               .select { |a| a.available_for_location?(@location) }

    # Gruppieren nach Typ und innerhalb jeder Gruppe alphabetisch nach
    # angezeigtem Namen (effective_attr berücksichtigt lokale Overrides).
    @available_products = (location_scoped + addons_for_location)
                            .group_by(&:type)
                            .transform_values do |products|
                              products.sort_by { |p| p.effective_attr("name").to_s.downcase }
                            end
  end

  def create
    location = Location.find(params[:location_id])
    product  = Product.find(params[:product_id])
    conf_type = params[:configurator_type] || "geschaeftsadresse"

    # Defense-in-Depth: Addons dürfen einer Location nur dann zugewiesen
    # werden, wenn sie für diese Location auch einen Preis besitzen.
    # Die UI filtert das ohnehin – aber der Endpunkt muss robust sein.
    if product.is_a?(Addon) && !product.available_for_location?(location)
      redirect_to admin_configurator_assignments_path(
                    location_id: location.id,
                    configurator_type: conf_type
                  ), alert: "Dieses Addon hat keinen Preis für #{location.effective_name} und kann daher nicht zugewiesen werden."
      return
    end

    assignment = ConfiguratorAssignment.new(
      location:          location,
      product:           product,
      configurator_type: conf_type,
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
                    configurator_type: conf_type
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
