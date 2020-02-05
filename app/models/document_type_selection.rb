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
        ## Add methods loops through the options and normalises them e.g.
        # {
        #     id: "news_story",
        #     type: "managed_elsewhere"
        #     managed_elsewhere_url: "http://foo"
        # }
        new(hash)
      end
    end
  end

  def parent
    self.class.all.find do |document_type_selection|
      document_type_selection.options.include?(id)
    end
  end
end
