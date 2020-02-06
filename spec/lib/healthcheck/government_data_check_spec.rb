# frozen_string_literal: true

RSpec.describe Healthcheck::GovernmentDataCheck do
  describe "#status" do
    context "government data is unavailable" do
      it "returns critical" do
        gov_data_check = Healthcheck::GovernmentDataCheck.new
        expect(gov_data_check.status).to be(:critical)
      end
    end

    context "government data is set to expire" do
      it "gives a warning" do
        populate_default_government_bulk_data
        gov_data_check = Healthcheck::GovernmentDataCheck.new
        travel_to(7.hours.from_now) do
          expect(gov_data_check.status).to be(:warning)
        end
      end
    end

    context "everything is fine" do
      it "returns ok" do
        populate_default_government_bulk_data
        gov_data_check = Healthcheck::GovernmentDataCheck.new
        expect(gov_data_check.status).to be(:ok)
      end
    end
  end

  describe "#details" do
    let(:gov_data_check) { Healthcheck::GovernmentDataCheck.new }
    it "displays appropriate messages" do
      populate_default_government_bulk_data
      allow_any_instance_of(BulkData::GovernmentRepository).to receive(:cache_age) { 1 }
      expect(gov_data_check.details[:warning]).to eq("Government data not refreshed in 0 hours 1 minutes")

      allow_any_instance_of(BulkData::GovernmentRepository).to receive(:cache_age) { 7200 }
      expect(gov_data_check.details[:warning]).to eq("Government data not refreshed in 2 hours 0 minutes")
    end
  end
end
