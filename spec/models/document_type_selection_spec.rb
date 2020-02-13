require "json"

RSpec.describe DocumentTypeSelection do
  let(:document_type_selections) { YAML.load_file(Rails.root.join("config/document_type_selections.yml")) }

  describe "all configured document type selections are valid" do
    document_type_selections = YAML.load_file(Rails.root.join("config/document_type_selections.yml"))
    document_type_selections.each do |document_type_selection|
      it "should have #{document_type_selection} conforming to document type selection schema" do
        expect(document_type_selection).to be_valid_against_schema("document_type_selection")
      end

      it "should have #{document_type_selection} conforming to document type selection locale schema" do
        translations = I18n.t("document_type_selections.#{document_type_selection['id']}").deep_stringify_keys
        expect(translations).to be_valid_against_schema("document_type_selection_locale")
      end

      it "should have #{document_type_selection} options conforming to document type selection locale schema" do
        document_type_selection["options"].each do |option|
          translations = I18n.t("document_type_selections.#{option['id']}").deep_stringify_keys
          expect(translations).to be_valid_against_schema("document_type_selection_locale")
        end
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

  describe ".parent" do
    it "should return nil if we pass it 'root'" do
      expect(DocumentTypeSelection.find("root").parent).to be_nil
    end

    it "should return a DocumentTypeSelection for the parent if it exists" do
      expect(DocumentTypeSelection.find("news").parent)
        .to eq("root")
    end
  end

  describe "SelectionOption" do
    describe ".id" do
      it "returns id of the option" do
        option = {
          "id" => "foo",
          "type" => "document_type",
        }

        expect(DocumentTypeSelection::SelectionOption.new(option).id).to eq("foo")
      end
    end

    describe ".type" do
      it "returns the type of the option" do
        option = {
          "id" => "foo",
          "type" => "document_type",
        }

        expect(DocumentTypeSelection::SelectionOption.new(option).type).to eq("document_type")
      end
    end

    describe ".managed_elsewhere_url" do
      let(:whitehall_host) { Plek.new.external_url_for("whitehall-admin") }

      it "returns nil if the type is not managed_elsewhere" do
        option = {
          "id" => "foo",
          "type" => "document_type",
          "path" => "/bar",
        }

        expect(DocumentTypeSelection::SelectionOption.new(option).managed_elsewhere_url).to be nil
      end

      it "returns the path if a hostname is not provided" do
        option = {
          "id" => "foo",
          "type" => "managed_elsewhere",
          "path" => "/bar",
        }

        expect(DocumentTypeSelection::SelectionOption.new(option).managed_elsewhere_url).to eq("/bar")
      end

      it "returns the full url if the hostname is provided" do
        option = {
          "id" => "foo",
          "type" => "managed_elsewhere",
          "hostname" => "whitehall-admin",
          "path" => "/bar",
        }

        expect(DocumentTypeSelection::SelectionOption.new(option).managed_elsewhere_url).to eq("#{whitehall_host}/bar")
      end
    end

    describe ".subtypes?" do
      it "returns true when the option is a parent" do
        option = {
          "id" => "foo",
          "type" => "parent",
        }

        expect(DocumentTypeSelection::SelectionOption.new(option).subtypes?).to be true
      end

      it "returns false when the option is not a parent" do
        option = {
          "id" => "foo",
          "type" => "document_type",
        }

        expect(DocumentTypeSelection::SelectionOption.new(option).subtypes?).to be false
      end
    end
  end
end
