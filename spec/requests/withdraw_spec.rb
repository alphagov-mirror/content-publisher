# frozen_string_literal: true

RSpec.describe "Withdraw" do
  let(:managing_editor) { create(:user, managing_editor: true) }
  let(:published_edition) { create(:edition, :published) }
  let(:history_mode_edition) { create(:edition, :published, :political, :past_government) }

  describe "POST /documents/:document/withdraw" do
    it "withdraws the edition" do
      stub_publishing_api_unpublish(published_edition.content_id, body: {})
      login_as(managing_editor)

      post withdraw_path(published_edition.document), params: { public_explanation: "Just cos" }
      follow_redirect!

      withdrawal = published_edition.reload.status.details
      expect(response.body).to include(
        I18n.t!("documents.show.withdrawn.title",
                document_type: published_edition.document_type.label.downcase,
                withdrawn_date: withdrawal.created_at.strftime("%-d %B %Y")),
      )
    end

    it "returns an error when publishing-api is down" do
      publishing_api_isnt_available
      login_as(managing_editor)

      post withdraw_path(published_edition.document), params: { public_explanation: "Just cos" }
      follow_redirect!

      expect(response.body).to include(I18n.t!("withdraw.new.flashes.publishing_api_error.title"))
    end

    it "returns a requirements error when there is a requirements issue" do
      login_as(managing_editor)
      post withdraw_path(published_edition.document), params: { public_explanation: "" }

      expect(response.body).to include(I18n.t!("requirements.public_explanation.blank.form_message"))
    end

    it "prevents users without managing_editor permission from withdrawing the edition" do
      post withdraw_path(published_edition.document), params: { public_explanation: "just cos" }

      expect(response.body).to include(I18n.t!("withdraw.no_managing_editor_permission.title"))
      expect(response).to have_http_status(:forbidden)
    end

    context "when the edition is in history mode" do
      it "lets managing_editors holding manage_live_history_mode permission withdraw the edition" do
        stub_publishing_api_unpublish(history_mode_edition.content_id, body: {})
        user = create(:user, managing_editor: true, manage_live_history_mode: true)
        login_as(user)

        post withdraw_path(history_mode_edition.document), params: { public_explanation: "Just cos" }
        follow_redirect!

        withdrawal = history_mode_edition.reload.status.details
        expect(response.body).to include(
          I18n.t!("documents.show.withdrawn.title",
                  document_type: history_mode_edition.document_type.label.downcase,
                  withdrawn_date: withdrawal.created_at.strftime("%-d %B %Y")),
        )
      end

      it "prevents managing_editors without manage_live_history_mode permission from withdrawing the edition" do
        login_as(managing_editor)

        post withdraw_path(history_mode_edition.document), params: { public_explanation: "Just cos" }

        expect(response.body).to include(I18n.t!("missing_permissions.update_history_mode.title", title: history_mode_edition.title))
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET /documents/:document/withdraw" do
    it "fetches withdraw page" do
      stub_publishing_api_unpublish(published_edition.content_id, body: {})
      login_as(managing_editor)

      get withdraw_path(published_edition.document)

      expect(response.body).to include(I18n.t!("withdraw.new.title", title: published_edition.title))
    end

    it "redirects to document summary when the edition is in the wrong state" do
      edition = create(:edition)
      login_as(managing_editor)

      get withdraw_path(edition.document)

      expect(response).to redirect_to(document_path(edition.document))
    end

    it "prevents users without managing_editor permission from accessing withdraw page" do
      get withdraw_path(published_edition.document)

      expect(response.body).to include(I18n.t!("withdraw.no_managing_editor_permission.title"))
      expect(response).to have_http_status(:forbidden)
    end

    context "when the edition is in history mode" do
      it "lets managing_editors holding manage_live_history_mode permission to access withdraw page" do
        stub_publishing_api_unpublish(history_mode_edition.content_id, body: {})
        user = create(:user, managing_editor: true, manage_live_history_mode: true)
        login_as(user)

        get withdraw_path(history_mode_edition.document)

        expect(response.body).to include(I18n.t!("withdraw.new.title", title: history_mode_edition.title))
      end

      it "prevents users without manage_live_history_mode permission from accessing withdraw page" do
        login_as(managing_editor)

        get withdraw_path(history_mode_edition.document)

        expect(response.body).to include(I18n.t!("missing_permissions.update_history_mode.title", title: history_mode_edition.title))
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
