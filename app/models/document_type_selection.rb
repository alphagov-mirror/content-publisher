# frozen_string_literal: true

class DocumentTypeSelection
  include InitializeWithHash

  attr_reader :id, :options

  def self.all
    @all ||= begin
      hashes = YAML.load_file(Rails.root.join("config/document_type_selections.yml"))

      hashes.map do |hash|
        new(hash)
      end
    end
  end
end
