# frozen_string_literal: true

RSpec.describe "Press release format" do
  include TopicsHelper

  before do
    stub_any_publishing_api_put_content
    stub_any_publishing_api_no_links
  end

  scenario do
    when_i_choose_this_document_type
    and_i_fill_in_the_form_fields
    and_i_add_some_tags
    then_i_can_publish_the_document
  end

  def when_i_choose_this_document_type
    visit root_path
    click_on "Create new document"
    choose I18n.t!("supertypes.news.label")
    click_on "Continue"
    choose DocumentType.find("press_release").label
    click_on "Continue"
  end

  def and_i_fill_in_the_form_fields
    fill_in "revision[title]", with: "A great title"
    fill_in "revision[summary]", with: "A great summary"

    document = Document.first
    base_path = Edition.last.document_type.path_prefix + "/a-great-title"
    stub_publishing_api_has_lookups(base_path => document.content_id)

    click_on "Save"
    reset_executed_requests!
  end

  def and_i_add_some_tags
    stub_publishing_api_has_links(role_appointment_links)

    expect(Edition.last.document_type.tags.count).to eq(5)
    stub_publishing_api_has_linkables([linkable], document_type: "topical_event")
    stub_publishing_api_has_linkables([linkable], document_type: "world_location")
    stub_publishing_api_has_linkables([linkable], document_type: "organisation")
    stub_publishing_api_has_linkables([linkable], document_type: "role_appointment")

    click_on "Change Tags"

    select linkable["internal_name"], from: "tags[topical_events][]"
    select linkable["internal_name"], from: "tags[world_locations][]"
    select linkable["internal_name"], from: "tags[primary_publishing_organisation][]"
    select linkable["internal_name"], from: "tags[organisations][]"
    select linkable["internal_name"], from: "tags[role_appointments][]"

    click_on "Save"
  end

  def then_i_can_publish_the_document
    expect(a_request(:put, /content/).with { |req|
             expect(req.body).to be_valid_against_publisher_schema("news_article")
           }).to have_been_requested
  end

  def role_appointment_links
    @role_appointment_links ||= {
      "content_id" => linkable["content_id"],
      "links" => {
        "person" => [SecureRandom.uuid],
        "role" => [SecureRandom.uuid],
      },
    }
  end

  def linkable
    @linkable ||= { "content_id" => SecureRandom.uuid, "internal_name" => "Linkable" }
  end
end
