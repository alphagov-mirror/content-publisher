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
    self.class.all.find do |document_type_selection|
      document_type_selection.options.map(&:id).include?(id)
    end
  end

  class SelectionOption
    attr_reader :option

    def initialize(option)
      @option = option
    end

    def id
      subtypes? ? option : option.keys.first
    end

    def type
      subtypes? ? "subtypes" : option["type"]
    end

    def label
      subtypes? ? option.titleize : option["label"]
    end

    def subtypes?
      option.is_a?(String)
    end

    def managed_elsewhere_url
      if option["hostname"]
        Plek.new.external_url_for(option.fetch("hostname")) + option.fetch("path")
      else
        option["path"]
      end
    end
  end
end
