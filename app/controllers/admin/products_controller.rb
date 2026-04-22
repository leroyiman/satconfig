class Admin::ProductsController < Admin::BaseController
  before_action :set_product, only: [:show, :update, :reset_override]

  def index
    @products = Product.includes(location: :city).order("cities.name, locations.name, products.type")

    @products = @products.where(type: params[:type])             if params[:type].present?
    @products = @products.where(location_id: params[:location_id]) if params[:location_id].present?

    if params[:overrides_only] == "1"
      @products = @products.where("local_attributes != '{}'::jsonb")
    end

    @locations = Location.active.includes(:city).order("cities.name, locations.name")
    @total     = @products.count
  end

  def show
    @translations = @product.product_translations.order(:language)
    @overridable  = AdminHelper::OVERRIDABLE_FIELDS[@product.type] || []
  end

  # PATCH /admin/products/:id
  # Speichert lokale Overrides für crm_attributes-Felder.
  # Leere Werte löschen das Override (= CRM-Wert gilt wieder).
  #
  # Für Addons werden Preise pro Location über
  #   params[:product][:prices_by_location] = { "<zoho_location_id>" => "1.60", ... }
  # übergeben.
  def update
    incoming = params.dig(:product, :local_attributes)&.permit! || {}

    current_locals = (@product.local_attributes || {}).dup

    incoming.each do |key, value|
      next if key.to_s == Addon::PRICES_BY_LOCATION_KEY # wird separat behandelt

      if value.blank?
        current_locals.delete(key.to_s)
      else
        current_locals[key.to_s] = value.to_s.strip
      end
    end

    # Per-Location-Preise für Addons
    if @product.is_a?(Addon)
      incoming_prices = params.dig(:product, :prices_by_location)
      incoming_prices = incoming_prices.to_unsafe_h if incoming_prices.respond_to?(:to_unsafe_h)

      if incoming_prices.is_a?(Hash)
        new_map = (current_locals[Addon::PRICES_BY_LOCATION_KEY] || {}).dup

        incoming_prices.each do |zoho_location_id, value|
          zid = zoho_location_id.to_s
          if value.blank?
            new_map.delete(zid)
          else
            new_map[zid] = value.to_s.strip
          end
        end

        if new_map.empty?
          current_locals.delete(Addon::PRICES_BY_LOCATION_KEY)
        else
          current_locals[Addon::PRICES_BY_LOCATION_KEY] = new_map
        end
      end
    end

    @product.update!(local_attributes: current_locals)
    redirect_to admin_product_path(@product),
                notice: "Preis-Overrides gespeichert."
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = "Fehler: #{e.message}"
    redirect_to admin_product_path(@product)
  end

  # PATCH /admin/products/:id/reset_override
  # ?field=price_3                          → nur dieses Feld zurücksetzen
  # ?location_zoho_id=226273000000051033    → Override für eine einzelne Location (Addon)
  # (kein param)                            → alle Overrides zurücksetzen
  def reset_override
    if params[:location_zoho_id].present? && @product.is_a?(Addon)
      zid = params[:location_zoho_id].to_s
      @product.reset_price_for_location!(zid)
      redirect_to admin_product_path(@product),
                  notice: "Preis-Override für Location zurückgesetzt."
    elsif params[:field].present?
      @product.reset_override!(params[:field])
      redirect_to admin_product_path(@product),
                  notice: "Override für '#{params[:field]}' zurückgesetzt."
    else
      @product.reset_all_overrides!
      redirect_to admin_product_path(@product),
                  notice: "Alle Preis-Overrides zurückgesetzt."
    end
  end

  private

  def set_product
    @product = Product.includes(location: :city).find(params[:id])
  end
end
