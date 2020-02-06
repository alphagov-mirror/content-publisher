# frozen_string_literal: true

RSpec.describe NewDocument::DocumentTypeSelectionInteractor do
  describe ".call" do
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

    it "returns the document_type of the selected option" do
      result = NewDocument::DocumentTypeSelectionInteractor.call(params: { document_type_selection_id: "root", selected_option_id: "news" })
      expect(result.document_type_id).to eq("news")
    end

    it "returns whether the selected option has subtypes" do
      result = NewDocument::DocumentTypeSelectionInteractor.call(params: { document_type_selection_id: "root", selected_option_id: "news" })
      expect(result.has_subtypes).to be true
    end

    it "returns the redirect url if the selected document type is mananged elsewhere" do
      result = NewDocument::DocumentTypeSelectionInteractor.call(params: { document_type_selection_id: "root", selected_option_id: "not-sure" })
      expect(result.redirect_url).to eq("/documents/publishing-guidance")
    end
  end
end
