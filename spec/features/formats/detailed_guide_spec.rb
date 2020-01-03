# frozen_string_literal: true

RSpec.describe "Detailed guide format" do
  scenario do
    when_i_choose_this_document_type
    then_i_am_redirected_to_another_app
  end

  def when_i_choose_this_document_type
    visit "/"
    click_on "Create new document"
    choose Supertype.find("guidance").label
    click_on "Continue"
    choose DocumentType.find("detailed_guide").label
    click_on "Continue"
  end

  def then_i_am_redirected_to_another_app
    expect(page.current_path).to eq("/government/admin/detailed-guides/new")
    expect(page).to have_content("You've been redirected")
  end
end
