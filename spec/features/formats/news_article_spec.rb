# frozen_string_literal: true

RSpec.describe "News article format" do
  include TopicsHelper

  before do
    stub_any_publishing_api_put_content
    stub_any_publishing_api_no_links
  end

  scenario do
    when_i_choose_this_document_type
    and_i_fill_in_the_form_fields
    and_i_add_some_tags
    then_the_document_should_be_publishable
  end

  def when_i_choose_this_document_type
    visit root_path
    click_on "Create new document"
    choose I18n.t!("supertypes.news.label")
    click_on "Continue"
    choose DocumentType.find("news_story").label
    click_on "Continue"
  end

  def and_i_fill_in_the_form_fields
    fill_in "revision[title]", with: "A great title"
    fill_in "revision[summary]", with: "A great summary"
    fill_in "revision[contents][body]", with: "Some body content"

    base_path = Edition.last.document_type.path_prefix + "/a-great-title"
    stub_publishing_api_has_lookups(base_path => Document.last.content_id)

    click_on "Save"
  end

  def and_i_add_some_tags
    # need to stub all linkables even though we're only selecting one
    stub_publishing_api_has_linkables([linkable], document_type: "topical_event")
    stub_publishing_api_has_linkables([linkable], document_type: "world_location")
    stub_publishing_api_has_linkables([linkable], document_type: "organisation")
    stub_publishing_api_has_linkables([linkable], document_type: "role_appointment")

    click_on "Change Tags"
    select linkable["internal_name"], from: "tags[primary_publishing_organisation][]"

    reset_executed_requests! # needed as we only care about the final request
    click_on "Save"
  end

  def then_the_document_should_be_publishable
    expect(a_request(:put, /content/).with { |req|
             expect(req.body).to be_valid_against_publisher_schema("news_article")
           }).to have_been_requested
    expect(page).to have_link("Publish", href: publish_confirmation_path(Document.last))
  end

  def linkable
    @linkable ||= { "content_id" => SecureRandom.uuid, "internal_name" => "Linkable" }
  end
end
