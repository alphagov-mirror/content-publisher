# frozen_string_literal: true

class BulkDataCache
  class Redis
    attr_reader :cache

    def initialize(namespace = "content-publisher_bulk-data-cache")
      @cache = ActiveSupport::Cache::RedisCacheStore.new(namespace: namespace)
    end

    def write(key, value)
      cache.write(key, value, expires_in: 24.hours)
    end

    def fetch(key)
      require "byebug"; byebug # DEBUG @kevindew
      cache.fetch(key) { raise NoEntryError }
    end

    def clear
      cache.clear
    end
  end
end

