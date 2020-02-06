# frozen_string_literal: true

class HealthcheckController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    healthcheck = GovukHealthcheck.healthcheck([
                    Healthcheck::GovernmentDataCheck,
                  ])
    render json: healthcheck
  end
end
