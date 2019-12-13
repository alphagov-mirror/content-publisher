# frozen_string_literal: true

RSpec.describe "Withdraw" do
  describe "POST /documents/:document/withdraw" do
    let(:content_id) { "f3bbdec2-0e62-4520-a7fd-6ffd5d36e03a" }
    let(:managing_editor) { create(:user, managing_editor: true) }
    let(:published_edition) { create(:edition, :published, document: create(:document, content_id: content_id)) }

    context "successfully withdraws the edition" do
      before { stub_publishing_api_unpublish(content_id, body: {}) }

      it "withdraws the edition" do
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

      it "lets users with correct permissions withdraw edition in history mode" do
        history_mode_edition = create(:edition, :published, :political, :past_government, document: create(:document, content_id: content_id))
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
    end

    context "fails to withdraw the edition" do
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

      it "prevents users without correct permissions from withdrawing the edition in history mode" do
        history_mode_edition = create(:edition, :published, :political, :past_government)
        login_as(managing_editor)

        post withdraw_path(history_mode_edition.document), params: { public_explanation: "Just cos" }

        expect(response.body).to include(I18n.t!("missing_permissions.update_history_mode.title", title: history_mode_edition.title))
        expect(response).to have_http_status(:forbidden)
      end

      it "prevents users without managing_editor permission from withdrawing the edition" do
        post withdraw_path(published_edition.document), params: { public_explanation: "just cos" }

        expect(response.body).to include(I18n.t!("withdraw.no_managing_editor_permission.title"))
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET /documents/:document/withdraw" do
    let(:managing_editor) { create(:user, managing_editor: true) }
    let(:published_edition) { create(:edition, :published) }

    context "successfully fetches the withdraw page" do
      it "renders the page" do
        login_as(managing_editor)

        get withdraw_path(published_edition.document)

        expect(response.body).to include(I18n.t!("withdraw.new.title", title: published_edition.title))
      end

      it "lets users with correct permissions access withdraw page in history mode" do
        history_mode_edition = create(:edition, :published, :political, :past_government)
        user = create(:user, managing_editor: true, manage_live_history_mode: true)
        login_as(user)

        get withdraw_path(history_mode_edition.document)

        expect(response.body).to include(I18n.t!("withdraw.new.title", title: history_mode_edition.title))
      end
    end

    context "fails to fetch the withdraw page" do
      it "redirects to document summary when the edition is in the wrong state" do
        draft_edition = create(:edition)
        login_as(managing_editor)

        get withdraw_path(draft_edition.document)

        expect(response).to redirect_to(document_path(draft_edition.document))
      end

      it "prevents users without correct permissions from accessing the withdraw page in history mode" do
        history_mode_edition = create(:edition, :published, :political, :past_government)
        login_as(managing_editor)

        get withdraw_path(history_mode_edition.document)

        expect(response.body).to include(I18n.t!("missing_permissions.update_history_mode.title", title: history_mode_edition.title))
        expect(response).to have_http_status(:forbidden)
      end

      it "prevents users without managing_editor permission from accessing withdraw page" do
        get withdraw_path(published_edition.document)

        expect(response.body).to include(I18n.t!("withdraw.no_managing_editor_permission.title"))
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
