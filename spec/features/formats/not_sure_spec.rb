# frozen_string_literal: true

RSpec.describe "User is not sure about the supertype" do
  scenario do
    when_i_click_on_create_a_document
    and_i_choose_i_am_not_sure_if_it_belongs_on_govuk
    then_i_see_the_guidance
  end

  def when_i_click_on_create_a_document
    visit "/"
    click_on "Create new document"
  end

  def and_i_choose_i_am_not_sure_if_it_belongs_on_govuk
    choose Supertype.find("not-sure").label
    click_on "Continue"
  end

  def then_i_see_the_guidance
    expect(page).to have_title(I18n.t!("new_document.guidance.title"))
  end
end
