class Configuration < ApplicationRecord
  # ── Associations ──────────────────────────────────────────────────────────
  belongs_to :location, optional: true
  belongs_to :product,  optional: true   # Hauptprodukt: VirtualOffice / CompanyHQ

  has_many :configuration_addons, dependent: :destroy
  has_many :addons, through: :configuration_addons, source: :addon

  # ── Validations ───────────────────────────────────────────────────────────
  validates :share_token, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[draft submitted] }

  # ── Scopes ────────────────────────────────────────────────────────────────
  scope :draft,     -> { where(status: "draft") }
  scope :submitted, -> { where(status: "submitted") }

  # ── Callbacks ─────────────────────────────────────────────────────────────
  before_validation :generate_token, on: :create

  # ── Step-Konstanten ───────────────────────────────────────────────────────
  STEPS = {
    1 => "Adresse",
    2 => "Typ",
    3 => "Erreichbarkeit",
    4 => "Meetings",
    5 => "Membership",
    6 => "Zusammenfassung",
    7 => "Anfrage"
  }.freeze

  TOTAL_STEPS = STEPS.keys.max

  # ── Addon-Kategorien je Step ──────────────────────────────────────────────
  STEP_ADDON_CATEGORIES = {
    3 => %w[Telefonservice Erreichbarkeit Post],
    4 => %w[Meetings],
    5 => %w[Membership],
    6 => %w[Upgrade]
  }.freeze

  # ── Step-Logik ────────────────────────────────────────────────────────────

  def step_name(step = current_step)
    STEPS[step]
  end

  def completed_step?(step)
    case step
    when 1 then location_id.present?
    when 2 then product_id.present?
    when 3..5 then current_step > step
    when 6 then current_step >= 6
    else false
    end
  end

  def accessible_step?(step)
    step <= current_step
  end

  # ── Addon-Helfer ──────────────────────────────────────────────────────────

  def addons_for_step(step)
    configuration_addons.where(step: step).includes(:addon).map(&:addon)
  end

  def addon_selected?(addon)
    configuration_addons.exists?(addon_id: addon.id)
  end

  def set_addons_for_step!(step, addon_ids)
    # Bestehende Addons für diesen Step entfernen
    configuration_addons.where(step: step).destroy_all

    # Neue Addons anlegen
    Array(addon_ids).reject(&:blank?).each do |addon_id|
      configuration_addons.find_or_create_by!(addon_id: addon_id, step: step)
    end

    recalculate_total!
  end

  # ── Preisberechnung ───────────────────────────────────────────────────────

  def recalculate_total!
    price = 0
    price += product_price   if product
    price += addons_total
    update_column(:total_price, price)
  end

  def product_price
    return 0 unless product
    # Verwende immer 12-Monats-Preis; Conference Rooms nutzen price_extern
    key = product.is_a?(ConferenceRoom) ? "price_extern" : "price_12"
    product.effective_attr(key).to_d
  end

  def addons_total
    addons.sum { |a| a.effective_attr("price_per_location").to_d }
  end

  def currency
    location&.currency || "EUR"
  end

  # ── Discount-Anzeige ──────────────────────────────────────────────────────
  # Gibt {original:, discounted:, percent:} zurück wenn ein Override vorliegt

  def product_price_display
    return nil unless product
    key = product.is_a?(ConferenceRoom) ? "price_extern" : "price_12"
    crm   = product.crm_attributes[key].to_d
    local = product.local_attributes[key]&.to_d
    return { current: crm } if local.nil? || local >= crm
    percent = (((crm - local) / crm) * 100).round
    { original: crm, current: local, discount_percent: percent }
  end

  def addon_price_display(addon)
    crm   = addon.crm_attributes["price_per_location"].to_d
    local = addon.local_attributes["price_per_location"]&.to_d
    return { current: crm } if local.nil? || local >= crm
    percent = (((crm - local) / crm) * 100).round
    { original: crm, current: local, discount_percent: percent }
  end

  # ── Submission ────────────────────────────────────────────────────────────

  def submit!(contact_params)
    assign_attributes(contact_params.merge(status: "submitted"))
    recalculate_total!
    save!
  end

  def submitted?
    status == "submitted"
  end

  private

  def generate_token
    self.share_token ||= SecureRandom.urlsafe_base64(16)
  end
end
