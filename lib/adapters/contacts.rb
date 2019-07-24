# frozen_string_literal: true

module Adapters
  class Contacts
    def find_by_content_id(content_id)

    end

    def all_by_organisation

    end

  private

    def all_contacts
      @all_contacts ||= Contacts::Store.new.fetch_contacts
    end
  end
end

require "adapters/contacts/store"
