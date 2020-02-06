# frozen_string_literal: true

module Healthcheck
  class GovernmentDataCheck
    def initialize
      @government_repo = BulkData::GovernmentRepository.new
    end

    def name
      :government_data_check
    end

    def status
      return GovukHealthcheck::CRITICAL unless @government_repo.cache_populated?
      return GovukHealthcheck::WARNING if @government_repo.cache_age > 6.hours

      GovukHealthcheck::OK
    end

    def details
      {
        critical: "No government data availible",
        warning: warning_details_content,
      }
    end

    def enabled?
      true
    end

  private

    def warning_details_content
      data_age = @government_repo.cache_age.to_i
      "Government data not refreshed in #{data_age / 3600} hours #{data_age % 60} minutes"
    end
  end
end
