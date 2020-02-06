# frozen_string_literal: true

RSpec.feature "Delete a file attachment" do
  scenario do
    given_there_is_an_edition_with_attachments
    when_i_insert_an_attachment
    and_i_delete_the_attachment
    then_i_see_the_attachment_is_gone
    and_i_see_the_timeline_entry
  end

  def given_there_is_an_edition_with_attachments
    body_field = DocumentType::BodyField.new
    document_type = build(:document_type, contents: [body_field])
    @attachment_revision = create(:file_attachment_revision, :on_asset_manager)

    @edition = create(:edition,
                      document_type: document_type,
                      file_attachment_revisions: [@attachment_revision])
  end

  def when_i_insert_an_attachment
    visit content_path(@edition.document)
    find("markdown-toolbar details").click
    click_on "Attachment"
  end

  def and_i_delete_the_attachment
    stub_publishing_api_put_content(@edition.content_id, {})
    expect(page).to have_selector(".gem-c-attachment__metadata")
    click_on "Delete attachment"
  end

  def then_i_see_the_attachment_is_gone
    expect(page).to have_content(I18n.t!("file_attachments.index.flashes.deleted", file: @attachment_revision.filename))
    expect(page).to_not have_selector("#file-attachment-#{@attachment_revision.file_attachment_id}")
  end

  def and_i_see_the_timeline_entry
    visit document_path(@edition.document)
    click_on "Document history"
    expect(page).to have_content(I18n.t!("documents.history.entry_types.file_attachment_deleted"))
  end
end
