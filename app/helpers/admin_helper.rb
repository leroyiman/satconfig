module AdminHelper
  # ── Produkt-Typ Anzeigenamen ───────────────────────────────────────────────
  PRODUCT_TYPE_LABELS = {
    "ConferenceRoom"     => "Conference Room",
    "Office"             => "Office",
    "VirtualOffice"      => "Virtual Office",
    "CompanyHeadquarter" => "Company HQ",
    "Addon"              => "Addon"
  }.freeze

  PRODUCT_TYPE_ICONS = {
    "ConferenceRoom"     => "fa-users",
    "Office"             => "fa-building",
    "VirtualOffice"      => "fa-wifi",
    "CompanyHeadquarter" => "fa-landmark",
    "Addon"              => "fa-puzzle-piece"
  }.freeze

  PRODUCT_TYPE_COLORS = {
    "ConferenceRoom"     => "primary",
    "Office"             => "success",
    "VirtualOffice"      => "info",
    "CompanyHeadquarter" => "warning",
    "Addon"              => "secondary"
  }.freeze

  # ── Überschreibbare Felder je Produkttyp ──────────────────────────────────
  # key:        jsonb-Schlüssel in crm_attributes / local_attributes
  # label:      Anzeigename in der UI
  # input_type: HTML input type
  # step:       Für number-Inputs (Dezimalstellen)
  OVERRIDABLE_FIELDS = {
    "ConferenceRoom" => [
      { key: "price_intern", label: "Preis Intern",  input_type: "number", step: "0.01", unit: "€" },
      { key: "price_extern", label: "Preis Extern",  input_type: "number", step: "0.01", unit: "€" }
    ],
    "Office" => [
      { key: "price_3",  label: "Preis 3 Monate",  input_type: "number", step: "0.01", unit: "€" },
      { key: "price_12", label: "Preis 12 Monate", input_type: "number", step: "0.01", unit: "€" }
    ],
    "VirtualOffice" => [
      { key: "price_3",  label: "Preis 3 Monate",  input_type: "number", step: "0.01", unit: "€" },
      { key: "price_12", label: "Preis 12 Monate", input_type: "number", step: "0.01", unit: "€" }
    ],
    "CompanyHeadquarter" => [
      { key: "price_3",  label: "Preis 3 Monate",  input_type: "number", step: "0.01", unit: "€" },
      { key: "price_12", label: "Preis 12 Monate", input_type: "number", step: "0.01", unit: "€" }
    ],
    "Addon" => [
      { key: "price_per_location", label: "Preis pro Location", input_type: "number", step: "0.01", unit: "€" }
    ]
  }.freeze

  # ── CRM-Felder (read-only Anzeige) je Produkttyp ──────────────────────────
  CRM_DISPLAY_FIELDS = {
    "ConferenceRoom" => [
      { key: "number_of_people", label: "Personen" },
      { key: "picture_id",       label: "Bild-ID (Zoho)" }
    ],
    "Office" => [
      { key: "square_meters",       label: "Fläche (m²)" },
      { key: "workspaces",          label: "Arbeitsplätze" },
      { key: "floor",               label: "Etage" },
      { key: "floor_plan_image_id", label: "Grundriss-ID (Zoho)" }
    ],
    "VirtualOffice"      => [],
    "CompanyHeadquarter" => [],
    "Addon" => [
      { key: "billing_type", label: "Abrechnung" },
      { key: "category",     label: "Kategorie" },
      { key: "unit",         label: "Einheit" },
      { key: "applies_to",   label: "Gilt für" }
    ]
  }.freeze

  # ── Helper-Methoden ────────────────────────────────────────────────────────

  def product_type_label(type)
    PRODUCT_TYPE_LABELS[type.to_s] || type.to_s
  end

  def product_type_icon(type)
    PRODUCT_TYPE_ICONS[type.to_s] || "fa-box"
  end

  def product_type_color(type)
    PRODUCT_TYPE_COLORS[type.to_s] || "secondary"
  end

  def overridable_fields_for(product)
    OVERRIDABLE_FIELDS[product.type] || []
  end

  def crm_display_fields_for(product)
    CRM_DISPLAY_FIELDS[product.type] || []
  end

  def format_price(value, currency = "€")
    return "—" if value.nil?
    "#{currency} #{format('%.2f', value.to_f)}"
  end

  def language_flag(lang)
    flags = { "de" => "🇩🇪", "en" => "🇬🇧", "fr" => "🇫🇷", "es" => "🇪🇸",
              "it" => "🇮🇹", "nl" => "🇳🇱", "pl" => "🇵🇱", "pt" => "🇵🇹" }
    flags[lang.to_s] || "🌐"
  end

  def applies_to_badges(applies_to_array)
    Array(applies_to_array).map do |t|
      content_tag(:span, product_type_label(t),
                  class: "badge bg-#{product_type_color(t)} me-1")
    end.join.html_safe
  end
end
