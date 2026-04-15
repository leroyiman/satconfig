class ConfiguratorAssignment < ApplicationRecord
  # ── Associations ──────────────────────────────────────────────────────────
  belongs_to :assignable, polymorphic: true

  # ── Konstanten ────────────────────────────────────────────────────────────
  CONFIGURATOR_TYPES = %w[geschaeftsadresse office meeting].freeze

  CONFIGURATOR_LABELS = {
    "geschaeftsadresse" => "Geschäftsadresse",
    "office"            => "Office",
    "meeting"           => "Meeting"
  }.freeze

  # Welche Steps welche Typen erwarten
  # Step nil = keine Step-Einschränkung (wird aus Typ abgeleitet)
  STEP_LABELS = {
    1 => "Adresse (Location)",
    2 => "Typ (Hauptprodukt)",
    3 => "Erreichbarkeit (Addons)",
    4 => "Meetings (Addons)",
    5 => "Membership (Addons)",
    6 => "Upgrade Angebote (Addons)"
  }.freeze

  # ── Validations ───────────────────────────────────────────────────────────
  validates :configurator_type, presence: true,
                                inclusion: { in: CONFIGURATOR_TYPES }
  validates :assignable_id,     uniqueness: {
    scope: [:configurator_type, :assignable_type],
    message: "ist bereits diesem Konfigurator zugewiesen"
  }

  # ── Scopes ────────────────────────────────────────────────────────────────
  scope :active,          -> { where(active: true) }
  scope :for_configurator, ->(type) { where(configurator_type: type, active: true) }
  scope :for_step,        ->(step) { where(step: step) }
  scope :locations,       -> { where(assignable_type: "Location") }
  scope :products,        -> { where(assignable_type: "Product") }
  scope :ordered,         -> { order(:position, :id) }

  # ── Class Methods ──────────────────────────────────────────────────────────

  # Gibt alle zugewiesenen Location-IDs für einen Konfigurator zurück
  def self.location_ids_for(configurator_type)
    for_configurator(configurator_type).locations.ordered.pluck(:assignable_id)
  end

  # Gibt alle zugewiesenen Product-IDs für einen Konfigurator + Step zurück
  def self.product_ids_for(configurator_type, step)
    for_configurator(configurator_type).products.for_step(step).ordered.pluck(:assignable_id)
  end

  # ── Instance Methods ───────────────────────────────────────────────────────

  def configurator_label
    CONFIGURATOR_LABELS[configurator_type] || configurator_type
  end

  def step_label
    STEP_LABELS[step] || "Alle Steps"
  end
end
