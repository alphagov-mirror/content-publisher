# frozen_string_literal: true

RSpec.describe "Remove tasks" do
  let(:edition) { create(:edition, :published, locale: "en") }

  describe "remove:gone" do
    before do
      Rake::Task["remove:gone"].reenable
    end

    it "removes the edition" do
      explanatory_note = "The reason the edition is being removed"
      alternative_url = "/path"

      unpublish_request = stub_publishing_api_unpublish(
        edition.content_id,
        body: {
          alternative_path: alternative_url,
          explanation: explanatory_note,
          locale: edition.locale,
          type: "gone",
        },
      )

      ClimateControl.modify URL: alternative_url, NOTE: explanatory_note do
        Rake::Task["remove:gone"].invoke(edition.content_id)
      end

      expect(unpublish_request).to have_been_requested
      expect(edition.reload).to be_removed
    end

    it "raises an error if a content_id is not present" do
      expect { Rake::Task["remove:gone"].invoke }
        .to raise_error("Missing content_id parameter")
    end

    it "raises an error if the document does not have a live version on GOV.uk" do
      draft = create(:edition, locale: "en")

      expect { Rake::Task["remove:gone"].invoke(draft.content_id) }
        .to raise_error("Document must have a published version before it can be removed")
    end
  end

  describe "remove:redirect" do
    before do
      Rake::Task["remove:redirect"].reenable
    end

    it "removes the edition with a redirect" do
      explanatory_note = "The reason the edition is being redirected"
      redirect_url = "/redirect-url"

      unpublish_request = stub_publishing_api_unpublish(
        edition.content_id,
        body: {
          alternative_path: redirect_url,
          explanation: explanatory_note,
          locale: edition.locale,
          type: "redirect",
        },
      )
      ClimateControl.modify URL: redirect_url, NOTE: explanatory_note do
        Rake::Task["remove:redirect"].invoke(edition.content_id)
      end

      expect(unpublish_request).to have_been_requested
      expect(edition.reload).to be_removed
    end

    it "raises an error if a content_id is not present" do
      expect { Rake::Task["remove:redirect"].invoke }
        .to raise_error("Missing content_id parameter")
    end

    it "raises an error if a URL is not present" do
      expect { Rake::Task["remove:redirect"].invoke("a-content-id") }
        .to raise_error("Missing URL value")
    end

    it "raises an error if the document does not have a live version on GOV.uk" do
      draft = create(:edition, locale: "en")

      ClimateControl.modify URL: "/redirect" do
        expect { Rake::Task["remove:redirect"].invoke(draft.content_id) }
          .to raise_error("Document must have a published version before it can be redirected")
      end
    end
  end
end