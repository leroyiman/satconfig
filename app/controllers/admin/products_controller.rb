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
  def update
    incoming = params.dig(:product, :local_attributes)&.permit! || {}

    current_locals = (@product.local_attributes || {}).dup

    incoming.each do |key, value|
      if value.blank?
        current_locals.delete(key.to_s)
      else
        current_locals[key.to_s] = value.strip
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
  # ?field=price_3  → nur dieses Feld zurücksetzen
  # (kein param)    → alle Overrides zurücksetzen
  def reset_override
    if params[:field].present?
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
