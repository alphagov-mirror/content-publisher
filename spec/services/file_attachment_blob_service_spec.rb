# frozen_string_literal: true

RSpec.describe FileAttachmentBlobService do
  let(:file) { fixture_file_upload("files/text-file.txt") }
  let(:revision) { build(:revision) }
  let(:instance) { FileAttachmentBlobService.new(revision) }


  describe "#save_file" do
    it "returns an empty hash when not given a file" do
      expect(instance.save_file(nil)).to eql({})
    end

    it "creates a blob and returns the id" do
      expect { instance.save_file(file) }
        .to change { ActiveStorage::Blob.count }
        .by(1)

      expect(instance.save_file(file))
        .to match(a_hash_including(blob_id: ActiveStorage::Blob.last.id))
    end

    it "returns the filename" do
      expect(instance.save_file(file))
        .to match(a_hash_including(filename: "text-file.txt"))
    end

    context "when the filename is used by an attachment for this revision" do
      let(:existing_attachment) { build(:file_attachment_revision, filename: "text-file.txt") }
      let(:revision) { build(:revision, file_attachment_revisions: [existing_attachment]) }

      it "updates the filename to be unique" do
        expect(instance.save_file(file))
          .to match(a_hash_including(filename: "text-file-1.txt"))
      end

      it "allows keeping the name if this is a replacement for the attachment with the same name" do
        expect(instance.save_file(file, replacing: existing_attachment))
          .to match(a_hash_including(filename: "text-file.txt"))
      end
    end

    context "when the upload is a pdf" do
      let(:file) { fixture_file_upload("files/13kb-1-page-attachment.pdf", "application/pdf") }

      it "returns the number of pages" do
        expect(instance.save_file(file))
          .to match(a_hash_including(number_of_pages: 1))
      end
    end

    context "when the upload is not a pdf" do
      it "returns nil for the number of pages" do
        expect(instance.save_file(file))
          .to match(a_hash_including(number_of_pages: nil))
      end
    end
  end
end
