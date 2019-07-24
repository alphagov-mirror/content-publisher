# frozen_string_literal: true

class BulkDataCache
  class Memory
    attr_reader :cache

    def initialize
      @cache = ActiveSupport::Cache::MemoryStore.new
    end

    def write(key, value)
      cache.write(key, value)
    end

    def fetch(key)
      cache.fetch(key) { raise NoEntryError }
    end

    def clear
      cache.clear
    end
  end
end
