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

    it "converts Whitehall image bang embeds to govspeak Image embeds" do
      body = described_class.call(body: "!!1", images: ["file.jpg"])

      expect(body).to eq("[Image:file.jpg]")
    end

    it "converts Whitehall attachment bang embeds to govspeak Attachment embeds" do
      body = described_class.call(body: "!@1", attachments: ["file.pdf"])

      expect(body).to eq("[Attachment:file.pdf]")
    end

    it "ignore Whitehall image bang embeds that are neither start of the string or preceeded by new lines" do
      body = described_class.call(
        body: "!!1 test !!2",
        images: ["file.png", "file.jpg"],
      )

      expect(body).to eq("[Image:file.png] test !!2")
    end

    it "ignore Whitehall attachment bang embeds that are neither start of the string or preceeded by new lines" do
      body = described_class.call(
        body: "!@1 test !@2",
        attachments: ["file.pdf", "file.csv"],
      )

      expect(body).to eq("[Attachment:file.pdf] test !@2")
    end

    it "ignore any image markdown that doesn't resolve to an image" do
      body = described_class.call(
        body: "Bar !!2 Baz",
        images: ["file.jpg"],
      )

      expect(body).to eq("Bar !!2 Baz")
    end

    it "ignore any attachment markdown that doesn't resolve to an attachment" do
      body = described_class.call(
        body: "Bar !@2 Baz",
        attachments: ["file.pdf"],
      )

      expect(body).to eq("Bar !@2 Baz")
    end

    it "converts image and attachment embeds prefixed by single new lines to be prefixed by two" do
      prefix_conversions = [
        { prefix: "\n", conversion: "\n\n" },
        { prefix: "\r\n", conversion: "\r\n\r\n" },
      ]

      prefix_conversions.each do |prefix_conversion|
        prefixed = []
        prefixed << "#{prefix_conversion[:prefix]}!!1"
        prefixed << "#{prefix_conversion[:prefix]}!@1"

        converted = []
        converted << "#{prefix_conversion[:conversion]}[Image:file.jpg]"
        converted << "#{prefix_conversion[:conversion]}[Attachment:file.pdf]"

        body = described_class.call(
          body: prefixed.join,
          images: ["file.jpg"],
          attachments: ["file.pdf"],
        )

        expect(body).to eq(converted.join)
      end
    end

    it "doesn't change the prefixes of images and attachments preceeded by two or more new lines" do
      prefixes = [
        "\n\n", "\r\n\r\n",
        "\n\n\n", "\r\n\r\n\r\n",
        "\n\n\n\n", "\r\n\r\n\r\n\r\n"
      ]

      prefixes.each do |prefix|
        body = described_class.call(
          body: "#{prefix}!!1#{prefix}!@1",
          images: ["file.jpg"],
          attachments: ["file.pdf"],
        )

        expect(body)
          .to eq("#{prefix}[Image:file.jpg]#{prefix}[Attachment:file.pdf]")
      end
    end

    it "converts Whitehall inline attachment syntax to Content Publisher syntax" do
      govspeak_body = described_class.call(
        body: "[InlineAttachment:1] test [InlineAttachment:2]",
        attachments: ["file.pdf", "download.csv"],
      )

      expect(govspeak_body)
        .to eq("[AttachmentLink:file.pdf] test [AttachmentLink:download.csv]")
    end
  end
end
