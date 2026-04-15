module Zoho
  # Einfaches Result-Objekt für Service-Rückgaben.
  # Vermeidet Exceptions als Kontrollfluss.
  #
  # Verwendung:
  #   Result.ok(city)           → success? == true,  value == city
  #   Result.fail("Fehler")     → success? == false, error == "Fehler"
  class Result
    attr_reader :value, :error

    def self.ok(value = nil)
      new(success: true, value: value)
    end

    def self.fail(error)
      new(success: false, error: error)
    end

    def success?
      @success
    end

    def failure?
      !@success
    end

    private

    def initialize(success:, value: nil, error: nil)
      @success = success
      @value   = value
      @error   = error
    end
  end
end
