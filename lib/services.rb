# frozen_string_literal: true

require "gds_api/whitehall"

module Services
  def self.whitehall(options = {})
    GdsApi::Whitehall.new(
      Plek.find("whitehall-admin"),
      { bearer_token: ENV["WHITEHALL_BEARER_TOKEN"] }.merge(options),
    )
  end
end
