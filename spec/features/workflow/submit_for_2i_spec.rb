RSpec.feature "Submit for 2i" do
  scenario do
    given_there_is_a_draft_edition
    when_i_visit_the_summary_page
    and_i_click_submit_for_2i
    then_i_see_the_edition_is_submitted
    and_i_see_a_link_to_the_edition
    and_i_see_the_timeline_entry
  end

  def given_there_is_a_draft_edition
    @edition = create(:edition, :publishable)
  end

  def when_i_visit_the_summary_page
    visit document_path(@edition.document)
  end

  def and_i_click_submit_for_2i
    click_on "Submit for 2i review"
  end

  def then_i_see_the_edition_is_submitted
    expect(page).to have_content I18n.t!("documents.show.submitted_for_review.title")
    expect(page).to have_content I18n.t!("user_facing_states.submitted_for_review.name")
  end

  def and_i_see_the_timeline_entry
    click_on "Document history"
    within first(".app-timeline-entry") do
      expect(page).to have_content I18n.t!("documents.history.entry_types.submitted")
    end
  end

  def and_i_see_a_link_to_the_edition
    review_url = find_field(I18n.t!("documents.show.submitted_for_review.label")).value
    expect(review_url).to match(document_url(@edition.document))
  end
end
