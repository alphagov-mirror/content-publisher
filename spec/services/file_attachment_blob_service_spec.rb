# frozen_string_literal: true

RSpec.describe FileAttachmentBlobService do
  let(:file) { fixture_file_upload("files/text-file.txt") }
  let(:user) { build(:user) }

  describe ".call" do
    it "creates a file attachment blob revision" do
      expect(FileAttachmentBlobService.call(file: file, filename: "file.txt"))
        .to be_a(FileAttachment::BlobRevision)
    end

    context "when the upload is a pdf" do
      let(:file) { fixture_file_upload("files/13kb-1-page-attachment.pdf", "application/pdf") }

      it "calculates the number of pages" do
        blob_revision = FileAttachmentBlobService.call(file: file, filename: "file.txt")
        expect(blob_revision.number_of_pages).to eql(1)
      end
    end

    context "when the upload is not a pdf" do
      it "sets nil for the number of pages" do
        blob_revision = FileAttachmentBlobService.call(file: file, filename: "file.txt")
        expect(blob_revision.number_of_pages).to be_nil
      end
    end
  end
end
