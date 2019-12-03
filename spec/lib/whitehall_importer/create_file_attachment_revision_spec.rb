# frozen_string_literal: true

RSpec.describe WhitehallImporter::CreateFileAttachmentRevision do
  let(:whitehall_file_attachment) do
    build(:whitehall_export_file_attachment)
  end

  context "creates a file attachment" do
    it "creates a FileAttachment::BlobRevision" do
      expect { described_class.call(whitehall_file_attachment) }
        .to change { FileAttachment::BlobRevision.count }.by(1)
    end

    it "creates a FileAttachment::Asset" do
      expect { described_class.call(whitehall_file_attachment) }
        .to change { FileAttachment::Asset.count }.by(1)
    end
  end
end
