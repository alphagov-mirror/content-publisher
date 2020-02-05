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
        if option.is_a? String
          expect(DocumentTypeSelection.find(option))
            .to be_a(DocumentTypeSelection)
        end
      end
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

  describe ".parent" do
    it "should return nil if we pass it 'root'" do
      expect(DocumentTypeSelection.find("root").parent).to be_nil
    end

    it "should return a DocumentTypeSelection for the parent if it exists" do
      expect(DocumentTypeSelection.find("news").parent)
        .to eq(DocumentTypeSelection.find("root"))
    end
  end

  describe "SelectionOption" do
    it "creates a hash when the option is a string" do
      expected_hash = {
        id: "foo",
        type: "refine",
      }
      expect(DocumentTypeSelection::SelectionOption.new("foo").hash).to eq(expected_hash)
    end

    it "sets the id correctly if option is an object" do
      option = {
        "foo" => nil,
        "type" => "document_type"
      }

      expected_hash = {
        id: "foo",
        type: "document_type"
      }

      expect(DocumentTypeSelection::SelectionOption.new(option).hash).to eq(expected_hash)
    end

    it "return the managed_elsewhere_url if the type is managed_elsewhere" do
      option = {
        "foo" => nil,
        "type" => "managed_elsewhere",
        "path" => "/bar"
      }

      expected_hash = {
        id: "foo",
        type: "managed_elsewhere",
        managed_elsewhere_url: "/bar"
      }

      expect(DocumentTypeSelection::SelectionOption.new(option).hash).to eq(expected_hash)
    end
  end
end
