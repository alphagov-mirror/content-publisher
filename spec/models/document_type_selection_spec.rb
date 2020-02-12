# frozen_string_literal: true

require "json"

RSpec.describe DocumentTypeSelection do
  let(:document_type_selections) { YAML.load_file(Rails.root.join("config/document_type_selections.yml")) }

  describe "all configured document types selections are valid" do
    let(:document_type_selection_schema) { JSON.parse(File.read("config/schemas/document_type_selection.json")) }

    it "should conform to the document type selection schema" do
      document_type_selections.each do |document_type_selection|
        validator = JSON::Validator.fully_validate(document_type_selection_schema, document_type_selection)
        expect(validator).to(
          be_empty,
          "Validation for #{document_type_selection['id']} failed: \n\t#{validator.join("\n\t")}",
        )
      end
    end

    it "should find the corresponding object for every string id in the options" do
      document_type_selections.flat_map { |d| d["options"] }.each do |option|
        if option["type"] == "parent"
          expect(DocumentTypeSelection.find(option["id"]))
            .to be_a(DocumentTypeSelection)
        end
      end
    end

    it "only allows unique document type selections" do
      ids = document_type_selections.pluck("id")
      expect(ids.size).to eq(ids.uniq.size)
    end
  end

  describe ".all" do
    it "should create a DocumentTypeSelection for each one in the YAML" do
      expect(DocumentTypeSelection.all.count).to eq(document_type_selections.count)
    end
  end

  describe ".find" do
    it "should return the hash of the corresponding DocumentTypeSelection" do
      expect(DocumentTypeSelection.find("news")).to be_a(DocumentTypeSelection)
    end

    it "raises a RuntimeError when there is no corresponding entry for the id" do
      expect { DocumentTypeSelection.find("unknown_document_type") }
        .to raise_error(RuntimeError, "Document type selection unknown_document_type not found")
    end
  end
end
