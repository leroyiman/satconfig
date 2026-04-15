module ConfiguratorHelper
  # Formatiert einen Preis: "250 €" oder "250,00 €"
  def format_conf_price(amount, currency = "EUR")
    return "0 €" if amount.blank? || amount.to_d == 0
    symbol = currency == "CHF" ? "CHF" : "€"
    val = amount.to_d
    # Kein Nachkomma wenn .00
    formatted = val == val.floor ? val.to_i.to_s : format("%.2f", val).gsub(".", ",")
    "#{formatted} #{symbol}"
  end

  # Gibt Preis-Hash {current:, original:, discount_percent:} für ein Produkt zurück
  def product_price_hash(product)
    return { current: 0 } unless product
    key = product.is_a?(ConferenceRoom) ? "price_extern" : "price_12"
    crm   = product.crm_attributes[key].to_d
    local = product.local_attributes[key]&.to_d
    return { current: crm } if local.nil? || local >= crm
    percent = (((crm - local) / crm) * 100).round
    { original: crm, current: local, discount_percent: percent }
  end

  def addon_price_hash(addon)
    crm   = addon.crm_attributes["price_per_location"].to_d
    local = addon.local_attributes["price_per_location"]&.to_d
    return { current: crm } if local.nil? || local >= crm
    percent = (((crm - local) / crm) * 100).round
    { original: crm, current: local, discount_percent: percent }
  end

  # Rendert den Preis-Block mit ggf. durchgestrichenem Original
  def render_price(price_hash, currency = "€", period: "pro Monat")
    parts = []
    if price_hash[:original]
      parts << content_tag(:span, "#{price_hash[:original].to_i} #{currency}",
                           class: "conf-card__price-original")
    end
    parts << content_tag(:span, "#{price_hash[:current].to_i} #{currency}",
                         class: "conf-card__price-value")
    if price_hash[:discount_percent]
      parts << content_tag(:span, "-#{price_hash[:discount_percent]}%",
                           class: "badge-discount ms-1")
    end
    parts << content_tag(:span, period, class: "conf-card__period ms-1")
    safe_join(parts, " ")
  end
end
