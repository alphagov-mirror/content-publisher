# frozen_string_literal: true

RSpec.feature "Editions" do
  background do
    given_there_is_a_published_edition
  end

  scenario "first edition" do
    when_i_visit_the_summary_page
    then_i_see_it_is_the_first_edition
  end

  scenario "major change" do
    when_i_visit_the_summary_page
    and_i_click_to_create_a_new_edition
    and_i_make_a_major_change
    then_i_see_there_is_a_new_major_edition
    and_i_see_the_new_edition_timeline_entry
  end

  scenario "minor change" do
    when_i_visit_the_summary_page
    and_i_click_to_create_a_new_edition
    and_i_make_a_minor_change
    then_i_see_there_is_a_new_minor_edition
  end

  scenario "discarded draft" do
    given_there_is_a_discarded_draft
    when_i_visit_the_summary_page
    and_i_click_to_create_a_new_edition
    and_i_make_a_minor_change
    then_i_see_the_draft_was_reset
    and_i_see_the_draft_reset_timeline_entry
  end

  def given_there_is_a_published_edition
    @published_edition = create(:edition,
                                :published,
                                update_type: "major",
                                change_note: "First edition.")
  end

  def given_there_is_a_discarded_draft
    create(:edition,
           document: @published_edition.document,
           state: :discarded,
           current: false)
  end

  def when_i_visit_the_summary_page
    visit document_path(@published_edition.document)
  end

  def then_i_see_it_is_the_first_edition
    expect(page).to_not have_content(I18n.t!("documents.show.contents.items.update_type"))
    expect(page).to_not have_content(I18n.t!("documents.show.contents.items.change_note"))
    expect(page).to_not have_link "Change Content"
  end

  def and_i_click_to_create_a_new_edition
    stub_any_publishing_api_put_content
    click_on "Create new edition"
  end

  def and_i_make_a_minor_change
    choose I18n.t!("content.edit.update_type.minor_name")
    click_on "Save"
  end

  def and_i_make_a_major_change
    fill_in "revision[change_note]", with: "I made a change"
    click_on "Save"
  end

  def then_i_see_there_is_a_new_minor_edition
    expect(page).to have_content(I18n.t!("documents.show.contents.update_type.minor"))
    expect(page).to_not have_content(I18n.t!("documents.show.contents.items.change_note"))
  end

  def then_i_see_there_is_a_new_major_edition
    expect(page).to have_content(I18n.t!("documents.show.contents.update_type.major"))
    expect(page).to have_content("I made a change")
    expect(page).to have_link("Change Content")
  end

  def and_i_see_the_new_edition_timeline_entry
    click_on "Document history"
    expect(page).to have_content(I18n.t!("documents.history.entry_types.new_edition"))
    expect(page).to have_content("2nd edition")
  end

  def then_i_see_the_draft_was_reset
    expect(page).to have_content(@published_edition.title)
  end

  def and_i_see_the_draft_reset_timeline_entry
    click_on "Document history"
    expect(page).to have_content I18n.t!("documents.history.entry_types.draft_reset")
  end
end
