# frozen_string_literal: true

RSpec.describe NewDocument::DocumentTypeSelectionInteractor do
  describe ".call" do
    let(:user) { build(:user, organisation_content_id: "org-id") }

    it "succeeds with valid paramaters" do
      result = NewDocument::DocumentTypeSelectionInteractor.call(params: { document_type_selection_id: "root", selected_option_id: "news" })
      expect(result).to be_success
    end

    it "fails if the selected_option_id is empty" do
      result = NewDocument::DocumentTypeSelectionInteractor.call(params: { document_type_selection_id: "root", selected_option_id: "" })
      expect(result).to_not be_success
    end

    it "fails if the selected_option_id isn't passed in" do
      result = NewDocument::DocumentTypeSelectionInteractor.call(params: { document_type_selection_id: "root" })
      expect(result).to_not be_success
    end

    it "returns whether the selected option has subtypes" do
      result = NewDocument::DocumentTypeSelectionInteractor.call(params: { document_type_selection_id: "root", selected_option_id: "news" })
      expect(result.needs_refining).to be true
    end

    it "returns the redirect url if the selected document type is mananged elsewhere" do
      result = NewDocument::DocumentTypeSelectionInteractor.call(params: { document_type_selection_id: "root", selected_option_id: "not-sure" })
      expect(result.redirect_url).to eq("/documents/publishing-guidance")
    end

    context "when the selected document type doesn't have subtypes and can be created" do
      it "creates a new document" do
        expect { NewDocument::DocumentTypeSelectionInteractor.call(params: { document_type_selection_id: "news", selected_option_id: "news_story" }, user: user) }
          .to change { Document.count }
          .by(1)
      end

      it "creates a timeline entry" do
        expect { NewDocument::DocumentTypeSelectionInteractor.call(params: { document_type_selection_id: "news", selected_option_id: "news_story" }, user: user) }
          .to change { TimelineEntry.count }
          .by(1)
      end
    end
  end
end
