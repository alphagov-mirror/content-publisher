# frozen_string_literal: true

RSpec.describe WhitehallImporter::EmbedBodyReferences do
  describe ".call" do
    it "changes the ids of embedded contacts" do
      content_id = SecureRandom.uuid
      govspeak_body = described_class.call(
        body: "[Contact:123]",
        contacts: [{ "id" => 123, "content_id" => content_id }],
      )

      expect(govspeak_body).to eq("[Contact:#{content_id}]")
    end

    it "converts Whitehall image syntax to Content Publisher syntax" do
      govspeak_body = described_class.call(
        body: "!!1 test !!2",
        images: ["foo.png", "bar.jpg"],
      )

      expect(govspeak_body).to eq("[Image:foo.png] test [Image:bar.jpg]")
    end

    it "removes any image markdown that doesn't resolve to an image" do
      govspeak_body = described_class.call(
        body: "Bar !!2 Baz",
        images: ["foo.png"],
      )

      expect(govspeak_body).to eq("Bar  Baz")
    end

    it "converts Whitehall attachment syntax to Content Publisher syntax" do
      govspeak_body = described_class.call(
        body: "!@1 test !@2",
        attachments: ["file.pdf", "download.csv"],
      )

      expect(govspeak_body).to eq("[Attachment:file.pdf] test [Attachment:download.csv]")
    end

    it "converts Whitehall inline attachment syntax to Content Publisher syntax" do
      govspeak_body = described_class.call(
        body: "[InlineAttachment:1] test [InlineAttachment:2]",
        attachments: ["file.pdf", "download.csv"],
      )

      expect(govspeak_body).to eq("[AttachmentLink:file.pdf] test [AttachmentLink:download.csv]")
    end
  end
end