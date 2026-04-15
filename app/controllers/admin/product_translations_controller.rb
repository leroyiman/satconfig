class Admin::ProductTranslationsController < Admin::BaseController
  before_action :set_translation

  # PATCH /admin/product_translations/:id
  def update
    local_name        = params.dig(:product_translation, :local_name)
    local_description = params.dig(:product_translation, :local_description)

    @translation.update!(
      local_name:        local_name.blank?        ? nil : local_name.strip,
      local_description: local_description.blank? ? nil : local_description.strip
    )

    redirect_to admin_product_path(@translation.product),
                notice: "Übersetzung (#{@translation.language.upcase}) gespeichert."
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = "Fehler: #{e.message}"
    redirect_to admin_product_path(@translation.product)
  end

  # PATCH /admin/product_translations/:id/reset_override
  # ?field=name | ?field=description | (kein param) → beide zurücksetzen
  def reset_override
    case params[:field]
    when "name"        then @translation.reset_name_override!
    when "description" then @translation.reset_description_override!
    else                    @translation.reset_all_overrides!
    end

    msg = case params[:field]
          when "name"        then "Name-Override (#{@translation.language.upcase}) zurückgesetzt."
          when "description" then "Beschreibungs-Override (#{@translation.language.upcase}) zurückgesetzt."
          else                    "Alle Übersetzungs-Overrides (#{@translation.language.upcase}) zurückgesetzt."
          end

    redirect_to admin_product_path(@translation.product), notice: msg
  end

  private

  def set_translation
    @translation = ProductTranslation.includes(:product).find(params[:id])
  end
end
