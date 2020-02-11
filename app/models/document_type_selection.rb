# frozen_string_literal: true

class DocumentTypeSelection
  include InitializeWithHash

  attr_reader :id, :options

  def self.find(id)
    item = all.find { |document_type_selection| document_type_selection.id == id }
    item || (raise RuntimeError, "Document type selection #{id} not found")
  end

  def self.all
    @all ||= begin
      hashes = YAML.load_file(Rails.root.join("config/document_type_selections.yml"))

      hashes.map do |hash|
        hash["options"].map! do |option|
          SelectionOption.new(option)
        end
        new(hash)
      end
    end
  end

  def parent
    parent = self.class.all.find do |document_type_selection|
      document_type_selection.options.map(&:id).include?(id)
    end

    parent.id if parent
  end

  class SelectionOption
    attr_reader :option

    def initialize(option)
      @option = option
    end

    def id
      option.keys.first
    end

    def type
      option["type"]
    end

    def subtypes?
      type == "parent"
    end

    def managed_elsewhere_url
      return unless managed_elsewhere?

      if option["hostname"]
        Plek.new.external_url_for(option.fetch("hostname")) + option.fetch("path")
      else
        option["path"]
      end
    end

    def managed_elsewhere?
      type == "managed_elsewhere"
    end
  end
end
