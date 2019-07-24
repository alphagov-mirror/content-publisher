# frozen_string_literal: true

module PopulateBulkDataCacheHelper
  def populate_contacts_cache(contacts)
    stub_publishing_api_get_editions(contacts, ContactsService::Repository::EDITION_PARAMS)
    ContactsService::Repository.new.populate_cache
  end
end
