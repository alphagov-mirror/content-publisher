# frozen_string_literal: true

RSpec.describe WhitehallImporter::DownloadFile do
  let(:image_url) { "https://assets.publishing.service.gov.uk/government/uploads/image.jpg" }

  context "file is available" do
    it "downloads file" do
      stub_request(:get, image_url).to_return(status: 200)
      file = described_class.call(image_url)

      expect(file).to have_requested(:get, image_url)
      expect(file).to be_an_instance_of(Tempfile)
    end
  end

  context "file is not available" do
    it "should raise a WhitehallImporter::AbortImportError" do
      stub_request(:get, image_url).to_return(status: 404)

      expect { described_class.call(image_url) }.to raise_error(
        WhitehallImporter::AbortImportError,
        "File does not exist: #{image_url}",
      )
    end
  end
end
