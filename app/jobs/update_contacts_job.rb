# frozen_string_literal: true

class UpdateContactsJob < ApplicationJob
  retry_on(ContactsService::RemoteDataUnavailableError,
           wait: :exponentially_longer,
           attempts: 3)

  def perform
    ApplicationRecord.with_advisory_lock("update-contacts", timeout_seconds: 0) do
      ContactsService::Repository.new.populate_cache
    end
  end
end
