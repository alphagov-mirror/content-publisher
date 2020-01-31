# frozen_string_literal: true

RSpec.feature "Upload file attachment", js: true do
  scenario do
    given_there_is_an_edition
    when_i_go_to_edit_the_edition
    and_i_go_to_insert_an_attachment
    and_i_upload_a_file_attachment
    then_i_can_see_previews_of_the_attachment
    and_i_see_the_timeline_entry
  end

  def given_there_is_an_edition
    body_field = DocumentType::BodyField.new
    document_type = build(:document_type, contents: [body_field])
    @edition = create(:edition, document_type_id: document_type.id)
  end

  def when_i_go_to_edit_the_edition
    visit document_path(@edition.document)
    click_on "Change Content"
  end

  def and_i_go_to_insert_an_attachment
    find("markdown-toolbar details").click
    click_on "Attachment"
  end

  def and_i_upload_a_file_attachment
    @attachment_filename = "13kb-1-page-attachment.pdf"
    @title = "A title"

    stub_asset_manager_receives_an_asset(filename: @attachment_filename)
    stub_publishing_api_put_content(@edition.content_id, {})

    find('form input[type="file"]').set(Rails.root.join(file_fixture(@attachment_filename)))
    fill_in "title", with: @title
    click_on "Upload"
  end

  def then_i_can_see_previews_of_the_attachment
    metadata = "PDF, 13 KB, 1 page"

    within(".gem-c-attachment") do
      expect(page).to have_content(@title)
      expect(page).to have_content(metadata)
    end

    within(".gem-c-attachment-link") do
      expect(page).to have_content(@title)
      expect(page).to have_content(metadata)
    end
  end

  def and_i_see_the_timeline_entry
    visit document_path(@edition.document)
    click_on "Document history"
    expect(page).to have_content I18n.t!("documents.history.entry_types.file_attachment_uploaded")
  end
end
