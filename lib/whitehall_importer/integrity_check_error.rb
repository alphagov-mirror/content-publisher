# frozen_string_literal: true

module WhitehallImporter
  class IntegrityCheckError < AbortImportError
    attr_reader :problems, :payload

    def initialize(state, integrity_check)
      @problems = integrity_check.problems
      @payload = integrity_check.proposed_payload
      super("#{state.titleize} integrity check failed")
    end
  end
end
