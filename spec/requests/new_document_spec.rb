# frozen_string_literal: true

RSpec.describe "New Document" do
  describe "GET /documents/show" do
    it "shows the root document type selection when no selection has been made" do
      get show_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to have_content(I18n.t!("document_type_selections.root.label"))
    end

    it "shows the page for the selected document type" do
      get show_path, params: { document_type_selection_id: "news" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to have_content("News")
    end
  end

  describe "POST /documents/select" do
    it "redirects to document edit content when a content publisher managed document type is selected" do
      post select_path, params: { document_type_selection_id: "news", selected_option_id: "news_story" }

      expect(response).to redirect_to(content_path(Document.last))
      follow_redirect!
      expect(response.body).to have_content("news story")
    end

    it "redirects when a document type managed elsewhere is selected" do
      post select_path, params: { document_type_selection_id: "root", selected_option_id: "not-sure" }

      expect(response).to redirect_to(guidance_url)
    end

    it "asks the user to refine their selection when the document type has subtypes" do
      post select_path, params: { document_type_selection_id: "root", selected_option_id: "news" }

      expect(response).to redirect_to(show_path(document_type_selection_id: "news"))
      follow_redirect!
      expect(response.body).to have_content("News")
    end

    it "returns an unprocessable response with an issue when a document type isn't selected" do
      post select_path, params: { document_type_selection_id: "news" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to have_content(
        I18n.t!("requirements.selected_option_id.not_selected.form_message"),
      )
    end
  end
end
