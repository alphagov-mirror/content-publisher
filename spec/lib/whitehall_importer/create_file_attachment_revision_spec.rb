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

  shared_examples "rejected file attachment" do
    it "raises an AbortImportError with an informative error" do
      create_revision = described_class.new(whitehall_file_attachment)
      expect { create_revision.call }.to raise_error(
        WhitehallImporter::AbortImportError,
        error_message,
      )
    end
  end

  context "file attachment does not satisfy requirements" do
    let(:too_long_title) { (("A" * Requirements::FileAttachmentChecker::TITLE_MAX_LENGTH) + "A") }
    let(:whitehall_file_attachment) { build(:whitehall_export_file_attachment, title: too_long_title) }
    let(:error_message) do
      I18n.t!("requirements.title.too_long.form_message", max_length: Requirements::FileAttachmentChecker::TITLE_MAX_LENGTH)
    end

    it_behaves_like "rejected file attachment"
  end

  context "whitehall attachment is of an unsupported type" do
    let(:whitehall_file_attachment) { build(:whitehall_export_file_attachment, type: "ExternalAttachment") }
    let(:error_message) { "Unsupported file attachment: #{whitehall_file_attachment['type']}" }

    it_behaves_like "rejected file attachment"
  end
end
