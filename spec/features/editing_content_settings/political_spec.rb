# frozen_string_literal: true

RSpec.feature "History mode" do
  scenario do
    given_there_is_a_not_political_document
    and_i_am_a_managing_editor
    when_i_visit_the_summary_page
    then_i_see_that_the_content_is_not_political
    when_i_click_to_change_the_status
    then_i_enable_political_status
    and_i_see_that_the_content_is_political
    and_i_see_the_timeline_entry
  end

  def given_there_is_a_not_political_document
    @edition = create(:edition, :not_political)
  end

  def and_i_am_a_managing_editor
    login_as(create(:user, :managing_editor))
  end

  def when_i_visit_the_summary_page
    visit document_path(@edition.document)
  end

  def then_i_see_that_the_content_is_not_political
    row = page.find(".govuk-summary-list__row", text: I18n.t!("documents.show.content_settings.political.title"))
    expect(row).to have_content(
      I18n.t!("documents.show.content_settings.political.false_label"),
    )
  end

  alias_method :and_i_see_that_the_content_is_not_political, :then_i_see_that_the_content_is_not_political

  def then_i_see_that_the_content_is_political
    row = page.find(".govuk-summary-list__row", text: I18n.t!("documents.show.content_settings.political.title"))
    expect(row).to have_content(
      I18n.t!("documents.show.content_settings.political.true_label"),
    )
  end

  alias_method :and_i_see_that_the_content_is_political, :then_i_see_that_the_content_is_political

  def when_i_click_to_change_the_status
    click_on "Change Gets history mode"
  end

  def then_i_enable_political_status
    @request = stub_publishing_api_put_content(@edition.content_id, {})
    choose(I18n.t!("political.edit.labels.political"))
    click_on "Save"
  end

  def and_i_see_the_timeline_entry
    within("#document-history") do
      expect(page).to have_content(I18n.t!("documents.history.entry_types.political_status_changed"))
    end
  end
end
