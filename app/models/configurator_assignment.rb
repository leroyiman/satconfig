class ConfiguratorAssignment < ApplicationRecord
  # ── Associations ──────────────────────────────────────────────────────────
  belongs_to :location
  belongs_to :product

  # ── Konstanten ────────────────────────────────────────────────────────────
  CONFIGURATOR_TYPES = %w[geschaeftsadresse office meeting].freeze

  CONFIGURATOR_LABELS = {
    "geschaeftsadresse" => "Geschäftsadresse",
    "office"            => "Office",
    "meeting"           => "Meeting"
  }.freeze

  STEP_LABELS = {
    2 => "Typ",
    3 => "Erreichbarkeit",
    4 => "Meetings",
    5 => "Membership",
    6 => "Upgrade-Angebote"
  }.freeze

  SELECTION_TYPES = %w[radio checkbox].freeze

  # ── Validations ───────────────────────────────────────────────────────────
  validates :configurator_type, inclusion: { in: CONFIGURATOR_TYPES }
  validates :selection_type,    inclusion: { in: SELECTION_TYPES }
  validates :step,              inclusion: { in: 2..6 }
  validates :product_id, uniqueness: {
    scope: [:location_id, :configurator_type],
    message: "ist bereits für diese Location zugewiesen"
  }

  # ── Scopes ────────────────────────────────────────────────────────────────
  scope :active,           -> { where(active: true) }
  scope :for_configurator, ->(type) { where(configurator_type: type) }
  scope :for_location,     ->(loc)  { where(location: loc) }
  scope :for_step,         ->(s)    { where(step: s) }
  scope :radio,            ->       { where(selection_type: "radio") }
  scope :checkbox,         ->       { where(selection_type: "checkbox") }
  scope :ordered,          ->       { order(:position, :id) }

  # ── Class helpers ─────────────────────────────────────────────────────────

  # Gibt [main_products, addon_products] für Location + Step zurück.
  # main_products  = selection_type "radio"    → Zeile 1
  # addon_products = selection_type "checkbox" → Zeile 2
  def self.split_for_step(location:, configurator_type:, step:)
    assignments = active
                    .for_location(location)
                    .for_configurator(configurator_type)
                    .for_step(step)
                    .ordered
                    .includes(:product)

    return [[], []] if assignments.empty?

    main   = assignments.select { |a| a.selection_type == "radio" }.map(&:product)
    addons = assignments.select { |a| a.selection_type == "checkbox" }.map(&:product)
    [main, addons]
  end

  def step_label
    STEP_LABELS[step] || "Step #{step}"
  end

  def configurator_label
    CONFIGURATOR_LABELS[configurator_type] || configurator_type
  end
end
