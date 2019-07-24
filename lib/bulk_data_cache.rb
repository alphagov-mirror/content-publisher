# frozen_string_literal: true

require "bulk_data_cache/redis"

class BulkDataCache
  include Singleton

  attr_reader :adapter
  delegate :write, :fetch, :clear, to: :adapter

  class NoEntryError < RuntimeError; end

  def self.write(key, value)
    instance.write(key, value)
  end

  def self.fetch(key)
    instance.fetch(key)
  end

  def self.clear
    instance.clear
  end

  def self.adapter
    instance.adapter
  end

private

  def initialize
    adapter_name = Rails.configuration.bulk_data_cache_adapter || :redis
    @adapter = "BulkDataCache::#{adapter_name.to_s.camelize}".constantize.new
  end
end
