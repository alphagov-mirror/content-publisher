# frozen_string_literal: true

class BulkDataCache
  include Singleton

  class NoEntryError < RuntimeError; end

  class << self
    delegate :write, :fetch, :clear, :cache, to: :instance
  end

  attr_reader :cache

  def write(key, value)
    cache.write(key, value, expires_in: 24.hours)
  end

  def fetch(key)
    cache.fetch(key) { raise NoEntryError }
  end

  def clear
    cache.clear
  end

private

  def initialize
    @cache = ActiveSupport::Cache::RedisCacheStore.new(
      namespace: "content-publisher:bulk-data-cache-#{Rails.env}"
    )
  end
end
