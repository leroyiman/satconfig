class ConfiguratorController < PublicController
  layout "configurator"

  before_action :load_configuration, except: [:new, :create]
  before_action :load_step_data,     only:   [:show]

  # GET /konfigurator
  # Erstellt sofort eine neue Konfiguration und leitet zu Step 1 weiter.
  def new
    @config = ::Configuration.create!
    redirect_to configurator_step_path(@config.share_token, 1)
  end

  def create
    @config = ::Configuration.create!
    redirect_to configurator_step_path(@config.share_token, 1)
  end

  # GET /konfigurator/:token/schritt/:step
  def show
    @step = params[:step].to_i
    redirect_to configurator_step_path(@config.share_token, @config.current_step) unless valid_step?
  end

  # PATCH /konfigurator/:token/schritt/:step
  def update
    @step = params[:step].to_i

    case @step
    when 1 then save_step_1
    when 2 then save_step_2
    when 3 then save_step_3
    when 4 then save_step_4
    when 5 then save_step_5
    when 6 then save_step_6
    when 7 then save_step_7
    end
  end

  # GET /konfigurator/:token/danke
  def submitted
    redirect_to configurator_path unless @config&.submitted?
  end

  private

  # ── Daten laden ───────────────────────────────────────────────────────────

  def load_configuration
    @config = ::Configuration.find_by(share_token: params[:token])
    redirect_to configurator_path if @config.nil?
  end

  def load_step_data
    @step            = params[:step].to_i
    @conf_type       = "geschaeftsadresse"
    @has_assignments = ConfiguratorAssignment.for_configurator(@conf_type).exists?

    case @step
    when 1
      @locations = assigned_locations
    when 2
      return redirect_to configurator_step_path(@config.share_token, 1) unless @config.location
      products = assigned_products_for_step(2)
      @virtual_offices      = products.select { |p| p.type == "VirtualOffice" }
      @company_headquarters = products.select { |p| p.type == "CompanyHeadquarter" }
    when 3
      return redirect_to configurator_step_path(@config.share_token, 2) unless @config.product
      step3_products = assigned_products_for_step(3)
      @phone_addons  = step3_products.select { |a| a.crm_attributes["category"] == "Telefonservice" }
      @post_addons   = step3_products.select { |a| a.crm_attributes["category"] == "Post" }
      @extra_addons  = step3_products.select { |a| a.crm_attributes["category"] == "Erreichbarkeit" }
      # Fallback wenn keine Assignments: Kategorie-basierte Abfrage
      if step3_products.empty? && !@has_assignments
        @phone_addons  = addons_for_categories(%w[Telefonservice])
        @post_addons   = addons_for_categories(%w[Post])
        @extra_addons  = addons_for_categories(%w[Erreichbarkeit])
      end
      @selected_addon_ids = @config.addons_for_step(3).map(&:id)
    when 4
      @meeting_packages = assigned_products_for_step(4).presence ||
                          (@has_assignments ? [] : addons_for_categories(%w[Meetings]))
      @selected_addon_ids = @config.addons_for_step(4).map(&:id)
    when 5
      @membership_options = assigned_products_for_step(5).presence ||
                            (@has_assignments ? [] : addons_for_categories(%w[Membership]))
      @selected_addon_ids = @config.addons_for_step(5).map(&:id)
    when 6
      already_chosen = @config.addon_ids
      @upgrade_addons = assigned_products_for_step(6).reject { |a| already_chosen.include?(a.id) }
      @upgrade_addons = addons_for_categories(%w[Upgrade]).where.not(id: already_chosen) if @upgrade_addons.empty? && !@has_assignments
      @selected_upgrade_ids = @config.addons_for_step(6).map(&:id)
    end
  end

  # ── Assignment-basierte Abfragen ──────────────────────────────────────────

  def assigned_locations
    ids = ConfiguratorAssignment.location_ids_for(@conf_type)
    if ids.any?
      # Reihenfolge aus Assignments beibehalten
      Location.active.includes(:city).where(id: ids)
              .sort_by { |l| ids.index(l.id) }
    else
      # Fallback: alle aktiven Locations (solange keine Assignments hinterlegt)
      Location.active.includes(:city).order("cities.name, locations.name")
    end
  end

  def assigned_products_for_step(step)
    ids = ConfiguratorAssignment.product_ids_for(@conf_type, step)
    return [] if ids.empty?
    Product.active.where(id: ids).sort_by { |p| ids.index(p.id) }
  end

  def addons_for_categories(categories)
    product_type = @config.product&.type
    scope = Addon.active.where("crm_attributes->>'category' IN (?)", categories)
    if product_type
      scope = scope.where("crm_attributes->'applies_to' @> ?", [product_type].to_json)
    end
    scope.order(Arel.sql("crm_attributes->>'name'"))
  end

  # ── Step-Speichern ────────────────────────────────────────────────────────

  def save_step_1
    location = Location.find_by(id: params[:location_id])
    return render_step_error("Bitte wähle eine Adresse.") unless location

    # Bei Location-Wechsel: nachfolgende Steps zurücksetzen
    if @config.location_id != location.id
      @config.configuration_addons.destroy_all
      @config.update!(product_id: nil, total_price: 0)
    end

    @config.update!(location: location, current_step: [2, @config.current_step].max)
    redirect_to configurator_step_path(@config.share_token, 2)
  end

  def save_step_2
    product = Product.find_by(id: params[:product_id])
    return render_step_error("Bitte wähle einen Typ.") unless product

    @config.update!(product: product, current_step: [3, @config.current_step].max)
    @config.recalculate_total!
    redirect_to configurator_step_path(@config.share_token, 3)
  end

  def save_step_3
    @config.set_addons_for_step!(3, params[:addon_ids])
    @config.update!(current_step: [4, @config.current_step].max)
    redirect_to configurator_step_path(@config.share_token, 4)
  end

  def save_step_4
    @config.set_addons_for_step!(4, params[:addon_ids])
    @config.update!(current_step: [5, @config.current_step].max)
    redirect_to configurator_step_path(@config.share_token, 5)
  end

  def save_step_5
    @config.set_addons_for_step!(5, params[:addon_ids])
    @config.update!(current_step: [6, @config.current_step].max)
    redirect_to configurator_step_path(@config.share_token, 6)
  end

  def save_step_6
    @config.set_addons_for_step!(6, params[:upgrade_ids])
    @config.update!(current_step: [7, @config.current_step].max)
    redirect_to configurator_step_path(@config.share_token, 7)
  end

  def save_step_7
    contact_params = params.require(:configuration).permit(
      :contact_first_name, :contact_last_name, :contact_company,
      :contact_address, :contact_postal_code, :contact_city,
      :contact_email, :contact_phone
    )

    unless contact_params[:contact_email].present? && contact_params[:contact_first_name].present?
      return render_step_error("Vorname und E-Mail sind Pflichtfelder.")
    end

    @config.submit!(contact_params)

    # TODO: Zoho Lead erstellen (Phase 3)
    # ZohoLeadService.new(@config).create_lead!

    redirect_to configurator_submitted_path(@config.share_token)
  end

  # ── Helpers ───────────────────────────────────────────────────────────────

  def valid_step?
    step = params[:step].to_i
    step.between?(1, ::Configuration::TOTAL_STEPS) && step <= @config.current_step
  end

  def render_step_error(message)
    flash.now[:alert] = message
    load_step_data
    render :show, status: :unprocessable_entity
  end
end
