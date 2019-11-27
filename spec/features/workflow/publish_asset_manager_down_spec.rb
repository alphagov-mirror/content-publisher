# frozen_string_literal: true

RSpec.feature "Publishing an edition when Asset Manager is down" do
  scenario do
    given_there_is_an_edition_with_a_lead_image
    and_asset_manager_is_down
    when_i_try_to_publish_the_edition
    then_i_see_the_publish_failed

    given_the_api_is_up_again_and_i_try_to_publish_the_edition
    then_i_see_the_publish_succeeded
  end

  def given_there_is_an_edition_with_a_lead_image
    image_revision = create(:image_revision, :on_asset_manager)
    @edition = create(:edition,
                      :publishable,
                      lead_image_revision: image_revision)
  end

  def and_asset_manager_is_down
    stub_asset_manager_isnt_available
    stub_any_publishing_api_put_content
    stub_any_publishing_api_publish
  end

  def when_i_try_to_publish_the_edition
    visit document_path(@edition.document)
    click_on "Publish"
    choose I18n.t!("publish.confirmation.has_been_reviewed")
    click_on "Confirm publish"
  end

  def then_i_see_the_publish_failed
    expect(page).to have_content(I18n.t!("documents.show.flashes.publish_error.title"))
  end

  def given_the_api_is_up_again_and_i_try_to_publish_the_edition
    @request = stub_asset_manager_updates_any_asset
    visit document_path(@edition.document)
    click_on "Publish"
    choose I18n.t!("publish.confirmation.has_been_reviewed")
    click_on "Confirm publish"
  end

  def then_i_see_the_publish_succeeded
    expect(@request).to have_been_requested.at_least_once
    expect(page).to have_content(I18n.t!("publish.published.reviewed.title"))
  end
end
