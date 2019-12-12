# frozen_string_literal: true

RSpec.describe "Unwithdraw" do
  let(:managing_editor) { create(:user, managing_editor: true) }
  let(:withdrawn_edition) { create(:edition, :withdrawn) }
  let(:history_mode_edition) { create(:edition, :withdrawn, :political, :past_government) }

  describe "POST /documents/:document/unwithdraw" do
    it "unwithdraws the edition" do
      stub_publishing_api_republish(withdrawn_edition.content_id, {})
      login_as(managing_editor)

      post unwithdraw_path(withdrawn_edition.document)
      follow_redirect!

      expect(response.body).to include(I18n.t!("documents.history.entry_types.unwithdrawn"))
    end

    it "returns an error when publishing-api is down" do
      publishing_api_isnt_available
      login_as(managing_editor)

      post unwithdraw_path(withdrawn_edition.document)
      follow_redirect!

      expect(response.body).to include(I18n.t!("withdraw.new.flashes.publishing_api_error.title"))
    end

    it "prevents users without managing_editor permission from unwithdrawing the edition" do
      post unwithdraw_path(withdrawn_edition.document)

      expect(response.body).to include(I18n.t!("unwithdraw.no_managing_editor_permission.title"))
      expect(response).to have_http_status(:forbidden)
    end

    context "when the edition is in history mode" do
      it "lets users holding manage_live_history_mode permisssion unwithdraw the edition" do
        stub_publishing_api_republish(history_mode_edition.content_id, {})
        user = create(:user, managing_editor: true, manage_live_history_mode: true)
        login_as(user)

        post unwithdraw_path(history_mode_edition.document)
        follow_redirect!

        expect(response.body).to include(I18n.t!("documents.history.entry_types.unwithdrawn"))
      end

      it "prevents users without manage_live_history_mode permisssion from unwithdrawing the edition" do
        login_as(managing_editor)

        post unwithdraw_path(history_mode_edition.document)

        expect(response.body).to include(I18n.t!("missing_permissions.update_history_mode.title", title: history_mode_edition.title))
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET /documents/:document/unwithdraw" do
    it "fetches unwithdraw page" do
      login_as(managing_editor)

      get unwithdraw_path(withdrawn_edition.document)
      follow_redirect!

      expect(response.body).to include(I18n.t!("documents.show.unwithdraw.title"))
    end

    it "redirects to document summary when the edition is in the wrong state" do
      edition = create(:edition, :published)
      login_as(managing_editor)

      get unwithdraw_path(edition.document)

      expect(response).to redirect_to(document_path(edition.document))
    end

    it "prevents users without managing_editor permission from accessing unwithdraw page" do
      get unwithdraw_path(withdrawn_edition.document)

      expect(response.body).to include(I18n.t!("unwithdraw.no_managing_editor_permission.title"))
      expect(response).to have_http_status(:forbidden)
    end

    context "when the edition is in history mode" do
      it "lets managing_editors holding manage_live_history_mode permisssion to access unwithdraw page" do
        user = create(:user, managing_editor: true, manage_live_history_mode: true)
        login_as(user)

        get unwithdraw_path(history_mode_edition.document)
        follow_redirect!

        expect(response.body).to include(I18n.t!("documents.show.unwithdraw.title"))
      end

      it "prevents users without manage_live_history_mode permisssion from accessing unwithdraw page" do
        login_as(managing_editor)

        get unwithdraw_path(history_mode_edition.document)

        expect(response.body).to include(I18n.t!("missing_permissions.update_history_mode.title", title: history_mode_edition.title))
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
