# frozen_string_literal: true

RSpec.describe WhitehallImporter::CreateFileAttachmentRevision do
  include FixturesHelper

  let(:whitehall_file_attachment) do
    whitehall_export_with_file_attachments["editions"].first["attachments"].first
  end

  context "creates a file attachment" do
    it "fetches file from asset-manager" do
      attachment = file_fixture("text-file.txt").read
      request = stub_request(:get, whitehall_file_attachment["url"]).to_return(status: 200, body: attachment)
      WhitehallImporter::CreateFileAttachmentRevision.new(whitehall_file_attachment).call

      expect(request).to have_been_requested.once
    end
  end

  context "aborts creating file attachment" do
    it "for an invalid url" do
      stub_request(:get, whitehall_file_attachment["url"]).to_return(status: 404)
      create_revision = WhitehallImporter::CreateFileAttachmentRevision.new(whitehall_file_attachment)

      expect{ create_revision.call }.to raise_error(
        AbortFileAttachmentError,
        "File attachment does not exist: #{whitehall_file_attachment['url']}"
      )
    end
  end
end
