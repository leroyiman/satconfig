class ProductTranslation < ApplicationRecord
  # ── Associations ──────────────────────────────────────────────────────────
  belongs_to :product

  # ── Validations ───────────────────────────────────────────────────────────
  validates :language,    presence: true
  validates :language,    uniqueness: { scope: :product_id }

  # ── Scopes ────────────────────────────────────────────────────────────────
  scope :for_language, ->(lang) { where(language: lang.to_s) }

  # ────────────────────────────────────────────────────────────────────────
  # EFFECTIVE VALUE LOGIC
  # local_* überschreibt crm_* – beide Werte bleiben gespeichert.
  # ────────────────────────────────────────────────────────────────────────

  # Gibt den effektiven Namen zurück (lokaler Override hat Vorrang)
  def effective_name
    local_name.presence || crm_name
  end

  # Gibt die effektive Description zurück (kann HTML/ul-Code enthalten)
  def effective_description
    local_description.presence || crm_description
  end

  # ── Override-Helpers ──────────────────────────────────────────────────────

  def name_overridden?
    local_name.present?
  end

  def description_overridden?
    local_description.present?
  end

  def reset_name_override!
    update!(local_name: nil)
  end

  def reset_description_override!
    update!(local_description: nil)
  end

  def reset_all_overrides!
    update!(local_name: nil, local_description: nil)
  end

  def to_s
    "#{product} [#{language}]"
  end
end
