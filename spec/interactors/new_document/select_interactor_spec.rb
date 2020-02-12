RSpec.describe NewDocument::SelectInteractor do
  describe ".call" do
    let(:user) { build(:user, organisation_content_id: "org-id") }

    it "succeeds with valid parameters" do
      result = described_class.call(params: { type: "root", selected_option_id: "news" })
      expect(result).to be_success
    end

    it "fails if the selected_option_id is empty" do
      result = described_class.call(params: { type: "root", selected_option_id: "" })
      expect(result).not_to be_success
    end

    it "fails if the selected_option_id isn't passed in" do
      result = described_class.call(params: { type: "root" })
      expect(result).not_to be_success
    end

    it "returns the previously selected document type selection" do
      document_type_selection = DocumentTypeSelection.find("root")

      result = described_class.call(params: { type: "root", selected_option_id: "news" })
      expect(result.document_type_selection.id).to eq(document_type_selection.id)
    end

    it "returns the current document type selection" do
      current_selection = DocumentTypeSelection.find("news")

      result = described_class.call(params: { type: "root", selected_option_id: "news" })
      expect(result.current_selection.id).to eq(current_selection.id)
    end

    it "returns the redirect url if the selected document type is managed elsewhere" do
      result = described_class.call(params: { type: "root", selected_option_id: "not_sure" })
      expect(result.redirect_url).to eq("/documents/publishing-guidance")
    end

    context "when the selected document type doesn't have subtypes and can be created" do
      let(:params) do
        {
          type: "news",
          selected_option_id: "news_story",
        }
      end

      it "creates a new document" do
        expect { described_class.call(params: params, user: user) }
          .to change(Document, :count)
          .by(1)
      end

      it "creates a timeline entry" do
        expect { described_class.call(params: params, user: user) }
          .to change(TimelineEntry, :count)
          .by(1)
      end
    end
  end
end
