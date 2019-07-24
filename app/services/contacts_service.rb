# frozen_string_literal: true

class ContactsService
  def initialize
    @repository = Repository.new
  end

  def by_content_id(content_id)
    all_contacts.find { |contact| contact["content_id"] == content_id }
  end

  def all_by_organisation
    @all_by_organisation ||= load_contacts_by_organisation
  end

private

  attr_reader :repository

  def all_contacts
    @all_contacts ||= repository.fetch_contacts
  end

  def organisation_select_options
    @organisation_select_options ||= LinkablesService.new("organisation").select_options
  end

  def load_contacts_by_organisation
    contacts_by_org = all_contacts.each_with_object({}) do |contact, memo|
      orgs = contact.dig("links", "organisations").to_a
      orgs.each do |content_id|
        memo[content_id] = memo[content_id].to_a + [contact]
      end
    end

    organisation_select_options.map do |(name, content_id)|
      {
        "name" => name,
        "content_id" => content_id,
        "contacts" => contacts_by_org.fetch(content_id, []),
      }
    end
  end

  class LocalDataUnavailableError < RuntimeError; end
  class RemoteDataUnavailableError < RuntimeError; end

  class Repository
    CACHE_KEY = "contacts-v1"
    EDITION_PARAMS = {
      document_types: %w[contact].freeze,
      fields: %w[content_id locale title description details links].freeze,
      states: %w[published].freeze,
      # This will need changing when this app supports more locales
      locale: "en",
      order: "id",
      per_page: 1000,
    }.freeze

    def fetch_contacts
      BulkDataCache.fetch(CACHE_KEY)
    rescue BulkDataCache::NoEntryError
      UpdateContactsJob.perform_later
      raise LocalDataUnavailableError
    end

    def populate_cache
      contacts = GdsApi.publishing_api_v2
                       .get_paged_editions(EDITION_PARAMS)
                       .inject([]) { |memo, page| memo + page["results"] }

      BulkDataCache.write(CACHE_KEY, contacts)
    rescue GdsApi::HTTPIntermittentServerError
      raise RemoteDataUnavailableError
    end
  end
end
