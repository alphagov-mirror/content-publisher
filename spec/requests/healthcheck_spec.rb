# frozen_string_literal: true

RSpec.describe "Healthcheck" do
  describe "GET /healthcheck" do
    context "when the healthchecks pass" do
      before do
        populate_default_government_bulk_data
      end
      it "returns a status of 'ok'" do
        get healthcheck_path
        expect(JSON.parse(response.body)["status"]).to eq("ok")
      end
    end

    it "includes useful information about each check" do
      get healthcheck_path

      expect(JSON.parse(response.body)["checks"]).to include(
        "database_connectivity" => { "status" => "ok" },
        "redis_connectivity" => { "status" => "ok" },
      )
    end
  end
end
