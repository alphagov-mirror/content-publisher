# frozen_string_literal: true

RSpec.describe WhitehallImporter::CreateEdition do
  include FixturesHelper

  describe "#call" do
    let(:whitehall_document) { whitehall_export_with_one_edition }
    let(:whitehall_edition) { whitehall_export_with_one_edition["editions"].first }
    let(:document) { create(:document, imported_from: "whitehall") }
    let(:user_ids) { { 1 => create(:user).id } }

    it "can import edition data from Whitehall" do
      WhitehallImporter::CreateEdition.new(
        document, whitehall_document, whitehall_edition, 1, user_ids
      ).call

      edition = Edition.last

      expect(edition.summary)
        .to eq(whitehall_edition["translations"][0]["summary"])

      expect(edition.number).to eql(1)
      expect(edition.status).to be_draft
      expect(edition.update_type).to eq("major")
    end

    it "sets live? to true when document state is 'published'" do
      whitehall_edition["state"] = "published"
      whitehall_edition["revision_history"] << {
        "event" => "update",
        "state" => "published",
        "whodunnit" => 1,
      }

      WhitehallImporter::CreateEdition.new(
        document, whitehall_document, whitehall_edition, 1, user_ids
      ).call

      expect(Edition.last).to be_live
    end

    it "can set minor update type" do
      whitehall_edition["minor_change"] = true

      WhitehallImporter::CreateEdition.new(
        document, whitehall_document, whitehall_edition, 1, user_ids
      ).call

      expect(Edition.last.update_type).to eq("minor")
    end

    it "sets live? to false when document state is 'rejected'" do
      whitehall_edition["state"] = "rejected"
      whitehall_edition["revision_history"] << {
        "event" => "update",
        "state" => "rejected",
        "whodunnit" => 1,
      }
      WhitehallImporter::CreateEdition.new(
        document, whitehall_document, whitehall_edition, 1, user_ids
      ).call

      expect(Edition.last).not_to be_live
    end

    it "sets live? to false when document state is 'submitted'" do
      whitehall_edition["state"] = "submitted"
      whitehall_edition["revision_history"] << {
        "event" => "update",
        "state" => "submitted",
        "whodunnit" => 1,
      }
      WhitehallImporter::CreateEdition.new(
        document, whitehall_document, whitehall_edition, 1, user_ids
      ).call

      expect(Edition.last).not_to be_live
    end

    it "raises AbortImportError when edition has an unsupported locale" do
      whitehall_edition["translations"][0]["locale"] = "zz"

      create_edition = WhitehallImporter::CreateEdition.new(
        document, whitehall_document, whitehall_edition, 1, user_ids
      )

      expect { create_edition.call }.to raise_error(WhitehallImporter::AbortImportError)
    end

    context "when importing a withdrawn document" do
      let(:whitehall_edition) { whitehall_export_with_one_withdrawn_edition["editions"].first }

      it "sets the correct states when Whitehall document state is withdrawn" do
        WhitehallImporter::CreateEdition.new(
          document, whitehall_document, whitehall_edition, 1, user_ids
        ).call

        expect(Status.count).to eq(2)
        expect(Status.first.state).to eq("published")
        expect(Edition.last.status).to be_withdrawn
        expect(Edition.last).to be_live
      end
    end
  end
end
