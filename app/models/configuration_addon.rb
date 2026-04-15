class ConfigurationAddon < ApplicationRecord
  belongs_to :configuration
  belongs_to :addon, class_name: "Product", foreign_key: :addon_id

  validates :step, presence: true,
                   inclusion: { in: [3, 4, 5, 6], message: "muss 3, 4, 5 oder 6 sein" }
  validates :addon_id, uniqueness: { scope: :configuration_id,
                                     message: "ist bereits in dieser Konfiguration" }
end
