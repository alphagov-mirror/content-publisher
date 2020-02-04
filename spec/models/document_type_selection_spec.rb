# frozen_string_literal: true

require "json"

RSpec.describe DocumentTypeSelection do
  let(:document_type_selections) { YAML.load_file(Rails.root.join("config/document_type_selections.yml")) }

  describe "all configured document types selections are valid" do
    it "should conform to the document type selection schema" do
      document_type_selection_schema = JSON.parse(File.read("config/schemas/document_type_selection.json"))
      document_type_selections.each do |document_type_selection|
        validator = JSON::Validator.fully_validate(document_type_selection_schema, document_type_selection)
        expect(validator).to(
          be_empty,
          "Validation for #{document_type_selection['id']} failed: \n\t#{validator.join("\n\t")}",
        )
      end
    end
  end

  describe ".all" do
    it "should create a DocumentType for each one in the YAML" do
      expect(DocumentTypeSelection.all.count).to eq(document_type_selections.count)
    end
  end
end
