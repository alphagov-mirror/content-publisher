require "json"

RSpec.describe DocumentTypeSelection::Option do
  describe ".managed_elsewhere?" do
    it "returns true if the option is managed_elsewhere" do
      option = {
        "id" => "foo",
        "type" => "managed_elsewhere",
      }

      expect(described_class.new(option).managed_elsewhere?).to be true
    end
  end

  describe ".managed_elsewhere_url" do
    let(:whitehall_host) { Plek.new.external_url_for("whitehall-admin") }

    it "returns the path if a hostname is not provided" do
      option = {
        "id" => "foo",
        "type" => "managed_elsewhere",
        "path" => "/bar",
      }

      expect(described_class.new(option).managed_elsewhere_url).to eq("/bar")
    end

    it "returns the full url if the hostname is provided" do
      option = {
        "id" => "foo",
        "type" => "managed_elsewhere",
        "hostname" => "whitehall-admin",
        "path" => "/bar",
      }

      expect(described_class.new(option).managed_elsewhere_url).to eq("#{whitehall_host}/bar")
    end
  end

  describe ".subtypes?" do
    it "returns true when the option is a parent" do
      option = {
        "id" => "foo",
        "type" => "parent",
      }

      expect(described_class.new(option).subtypes?).to be true
    end

    it "returns false when the option is not a parent" do
      option = {
        "id" => "foo",
        "type" => "document_type",
      }

      expect(described_class.new(option).subtypes?).to be false
    end
  end
end
