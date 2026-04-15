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
    @step      = params[:step].to_i
    @conf_type = "geschaeftsadresse"
    location   = @config.location

    case @step
    when 1
      # Step 1: Alle aktiven Locations, alphabetisch.
      # Ausgenommen: im Admin als "verborgen" markierte.
      @locations = Location.active
                           .includes(:city)
                           .where("locations.local_attributes->>'configurator_hidden' IS DISTINCT FROM 'true'")
                           .order("locations.name")

    when 2
      return redirect_to configurator_step_path(@config.share_token, 1) unless location
      @main_products, @addon_products = products_for_step(2, location)
      # Fallback wenn keine Assignments: alle VO + CompanyHQ der Location
      if @main_products.empty? && @addon_products.empty?
        @main_products = location.products
                                 .where(type: %w[VirtualOffice CompanyHeadquarter])
                                 .active.to_a
      end

    when 3
      return redirect_to configurator_step_path(@config.share_token, 2) unless @config.product
      @main_products, @addon_products = products_for_step(3, location)
      # Fallback: Addons der Location nach Kategorie
      if @main_products.empty? && @addon_products.empty?
        all = location_addons_for(location)
        @main_products  = all.select { |a| a.crm_attributes["category"] == "Telefonservice" }
        @addon_products = all.select { |a| %w[Erreichbarkeit Post].include?(a.crm_attributes["category"]) }
      end
      @selected_addon_ids = @config.addons_for_step(3).map(&:id)

    when 4
      @main_products, @addon_products = products_for_step(4, location)
      @main_products = location_addons_for(location, categories: %w[Meetings]) if @main_products.empty? && @addon_products.empty?
      @selected_addon_ids = @config.addons_for_step(4).map(&:id)

    when 5
      @main_products, @addon_products = products_for_step(5, location)
      @main_products = location_addons_for(location, categories: %w[Membership]) if @main_products.empty? && @addon_products.empty?
      @selected_addon_ids = @config.addons_for_step(5).map(&:id)

    when 6
      already_chosen = @config.addon_ids
      main, addons   = products_for_step(6, location)
      @main_products  = main.reject  { |p| already_chosen.include?(p.id) }
      @addon_products = addons.reject { |p| already_chosen.include?(p.id) }
      if @main_products.empty? && @addon_products.empty?
        @main_products = location_addons_for(location, categories: %w[Upgrade])
                           .reject { |p| already_chosen.include?(p.id) }
      end
      @selected_upgrade_ids = @config.addons_for_step(6).map(&:id)
    end
  end

  # Gibt [main_products, addon_products] für einen Step zurück.
  # Liest aus ConfiguratorAssignments (location-spezifisch).
  def products_for_step(step, location)
    return [[], []] unless location
    ConfiguratorAssignment.split_for_step(
      location: location,
      configurator_type: @conf_type,
      step: step
    )
  end

  # Fallback: Addons der Location nach Kategorie + applies_to
  def location_addons_for(location, categories: nil)
    return [] unless location
    scope = location.products.where(type: "Addon").active
    scope = scope.where("crm_attributes->>'category' IN (?)", categories) if categories.present?
    product_type = @config.product&.type
    scope = scope.where("crm_attributes->'applies_to' @> ?", [product_type].to_json) if product_type
    scope.order(Arel.sql("crm_attributes->>'name'")).to_a
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
