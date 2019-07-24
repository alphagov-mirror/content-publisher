# frozen_string_literal: true

require "bulk_data_cache"

module Adapters
  class Contacts::Store
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

    class DataUnavailableError < RuntimeError; end

    def fetch_contacts
      BulkDataCache.fetch(CACHE_KEY)
    rescue BulkDataCache::NoEntryError
      raise DataUnavailableError
    end

    def populate_cache
      BulkDataCache.write(CACHE_KEY, load_all_contacts)
    end

  private

    attr_reader :bulk_data_cache

    def load_all_contacts
      GdsApi
        .publishing_api_v2
        .get_paged_editions(EDITION_PARAMS)
        .inject([]) { |memo, page| memo + page["results"] }
    # rescue GdsApi::Error
    #   maybe raise our own error here
    end
  end
end
