RSpec.describe Organisations do
  describe "#alternative_format_contact_email" do
    context "when the edition has a primary org" do
      let(:org_content_id) { SecureRandom.uuid }

      let(:edition) do
        build :edition, tags: { primary_publishing_organisation: [org_content_id] }
      end

      context "when the primary org has an alt email" do
        before do
          stub_publishing_api_has_item(
            content_id: org_content_id,
            details: {
              alternative_format_contact_email: "foo@bar.com",
            },
          )
        end

        it "returns the specified email" do
          email = described_class.new(edition).alternative_format_contact_email
          expect(email).to eq "foo@bar.com"
        end
      end

      context "when the primary org has no alt email" do
        before do
          stub_publishing_api_has_item(
            content_id: org_content_id,
            details: {
              alternative_format_contact_email: "",
            },
          )
        end

        it "returns the default alt email" do
          email = described_class.new(edition).alternative_format_contact_email
          expect(email).to eq Organisations::DEFAULT_ALTERNATIVE_FORMAT_CONTACT_EMAIL
        end
      end

      context "when the primary org is not found" do
        before do
          stub_any_publishing_api_call_to_return_not_found
        end

        it "returns the default alt email" do
          email = described_class.new(edition).alternative_format_contact_email
          expect(email).to eq Organisations::DEFAULT_ALTERNATIVE_FORMAT_CONTACT_EMAIL
        end
      end
    end

    context "when the edition has no primary org" do
      let(:edition) { build :edition }

      it "returns the default alt email" do
        email = described_class.new(edition).alternative_format_contact_email
        expect(email).to eq Organisations::DEFAULT_ALTERNATIVE_FORMAT_CONTACT_EMAIL
      end
    end
  end
end
