# frozen_string_literal: true

RSpec.describe WhitehallImporter::CreateFileAttachmentRevision do
  let(:whitehall_file_attachment) do
    build(:whitehall_export_file_attachment)
  end

  context "creates a file attachment" do
    it "fetches file from asset-manager" do
      create_revision = described_class.new(whitehall_file_attachment)
      expect(create_revision.call).to have_requested(:get, whitehall_file_attachment["url"])
    end

    it "creates a FileAttachment::Revision and sets correct metadata" do
      revision = nil
      expect { revision = described_class.call(whitehall_file_attachment) }
        .to change { FileAttachment::Revision.count }.by(1)

      expect(revision.metadata_revision.title).to eq(whitehall_file_attachment["title"])
      expect(revision.filename).to eq("some-txt.txt")
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

  context "file attachment URL is invalid" do
    let(:error_message) { "File attachment does not exist: #{whitehall_file_attachment['url']}" }
    before { stub_request(:get, whitehall_file_attachment["url"]).to_return(status: 404) }

    it_behaves_like "rejected file attachment"
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