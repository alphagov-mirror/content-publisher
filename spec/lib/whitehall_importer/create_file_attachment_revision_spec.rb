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

    it "creates a FileAttachment::Revision" do
      expect { described_class.call(whitehall_file_attachment) }
        .to change { FileAttachment::Revision.count }.by(1)
    end

    it "creates a FileAttachment::MetadataRevision" do
      metadata_revision = nil
      expect { metadata_revision = described_class.call(whitehall_file_attachment) }
        .to change { FileAttachment::MetadataRevision.count }.by(1)

      expect(metadata_revision.title).to eq(whitehall_file_attachment["title"])
    end

    it "creates a FileAttachment::Asset" do
      expect { described_class.call(whitehall_file_attachment) }
        .to change { FileAttachment::Asset.count }.by(1)
    end
  end

  context "aborts creating a file attachment" do
    it "for a file attachment with requirements issues" do
      too_long_title = ("A" * Requirements::FileAttachmentChecker::TITLE_MAX_LENGTH) + "A"
      whitehall_file_attachment = build(
        :whitehall_export_file_attachment,
        title: too_long_title,
      )

      expect { described_class.call(whitehall_file_attachment) }.to raise_error(
        WhitehallImporter::AbortImportError,
        I18n.t!("requirements.title.too_long.form_message", max_length: Requirements::FileAttachmentChecker::TITLE_MAX_LENGTH),
      )
    end

    it "for a whitehall attachment with unsupported type" do
      whitehall_attachment = build(:whitehall_export_file_attachment, type: "ExternalAttachment")

      expect { described_class.call(whitehall_attachment) }.to raise_error(
        WhitehallImporter::AbortImportError,
        "Unsupported file attachment: #{whitehall_attachment['type']}",
      )
    end
  end
end
