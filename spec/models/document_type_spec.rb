require "json"

RSpec.describe DocumentType do
  let(:document_types) { YAML.load_file(Rails.root.join("config/document_types.yml")) }

  describe "all configured document types are valid" do
    it "should conform to the document type schema" do
      document_types.each do |document_type|
        expect(document_type).to be_valid_against_schema("document_type")
      end
    end

    it "should have locale keys that conform to the document type locale schema" do
      document_types.each do |document_type|
        translations = I18n.t("document_types.#{document_type['id']}").deep_stringify_keys
        expect(translations).to be_valid_against_schema("document_types_locale")
      end
    end

    it "should have a valid document type that exists in GovukSchemas" do
      document_types.each do |document_type|
        expect(document_type["id"]).to be_in(GovukSchemas::DocumentTypes.valid_document_types)
      end
    end
  end

  describe ".all" do
    it "should create a DocumentType for each one in the YAML" do
      expect(DocumentType.all.count).to eq(document_types.count)
    end
  end

  describe ".find" do
    it "returns a DocumentType when it's a known document_type" do
      expect(DocumentType.find("press_release")).to be_a(DocumentType)
    end

    it "raises a RuntimeError when we don't know the document_type" do
      expect { DocumentType.find("unknown_document_type") }
        .to raise_error(RuntimeError, "Document type unknown_document_type not found")
    end
  end

  describe ".clear" do
    it "resets the DocumentType.all return value" do
      preexisting_doctypes = DocumentType.all.count
      build(:document_type)
      expect(DocumentType.all.count).to eq(preexisting_doctypes + 1)
      DocumentType.clear
      expect(DocumentType.all.count).to eq(preexisting_doctypes)
    end
  end
end
