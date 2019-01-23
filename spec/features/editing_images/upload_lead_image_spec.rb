# frozen_string_literal: true

RSpec.feature "Upload a lead image" do
  include AssetManagerHelper

  scenario do
    given_there_is_an_edition
    when_i_visit_the_images_page
    and_i_upload_a_new_image
    and_i_crop_the_image
    and_i_fill_in_the_metadata
    then_i_see_the_new_lead_image
    and_the_preview_creation_succeeded
  end

  def given_there_is_an_edition
    document_type = build(:document_type, lead_image: true)
    @edition = create(:edition, document_type_id: document_type.id)
  end

  def when_i_visit_the_images_page
    visit images_path(@edition.document)
  end

  def and_i_upload_a_new_image
    stub_asset_manager_receives_assets("1000x1000.jpg")

    find('form input[type="file"]').set(Rails.root.join(file_fixture("1000x1000.jpg")))
    click_on "Upload"
  end

  def and_i_crop_the_image
    stub_publishing_api_put_content(@edition.content_id, {})
    click_on "Crop image"
    reset_executed_requests!
  end

  def and_i_fill_in_the_metadata
    fill_in "image_revision[alt_text]", with: "Some alt text"
    fill_in "image_revision[caption]", with: "A caption"
    fill_in "image_revision[credit]", with: "A credit"
    @request = stub_publishing_api_put_content(@edition.content_id, {})
    click_on "Save and choose"
  end

  def then_i_see_the_new_lead_image
    expect(page).to have_content(I18n.t!("documents.show.flashes.lead_image.added", file: "1000x1000.jpg"))
    expect(page).to have_content("A caption")
    expect(page).to have_content("A credit")
    expect(find("#lead-image img")["src"]).to include("1000x1000.jpg")
    expect(find("#lead-image img")["alt"]).to eq("Some alt text")
    expect(page).to have_content(I18n.t!("documents.history.entry_types.lead_image_updated"))
    expect(page).to have_content(I18n.t!("documents.history.entry_types.image_updated"))
  end

  def and_the_preview_creation_succeeded
    expect(@request).to have_been_requested
    expect(page).to have_content(I18n.t!("user_facing_states.draft.name"))

    expect(a_request(:put, /content/).with { |req|
      expect(JSON.parse(req.body)["details"]["image"]["url"]).to match(/1000x1000.jpg/)
      expect(JSON.parse(req.body)["details"]["image"]["alt_text"]).to eq("Some alt text")
      expect(JSON.parse(req.body)["details"]["image"]["caption"]).to eq("A caption")
    }).to have_been_requested
  end
end
