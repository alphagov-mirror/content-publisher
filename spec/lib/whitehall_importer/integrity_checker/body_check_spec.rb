RSpec.describe WhitehallImporter::IntegrityChecker::BodyCheck do
  describe "#content_problems" do
    let(:proposed_payload) do
      {
        content_id: "ABC123",
        base_path: "/path-to-document",
        title: "Document Title",
        description: "Some description",
        document_type: "news_story",
        schema_name: "schema_name",
        details: {
          body: "Some text",
        },
      }
    end

    let(:publishing_api_content) do
      {
        content_id: "ABC123",
        base_path: "/path-to-document",
        title: "Document Title",
        description: "Some description",
        document_type: "news_story",
        schema_name: "schema_name",
        details: {
          body: "Some text",
        },
      }
    end

    it "retuns no problems if the proposed payload matches" do
      integrity_check = WhitehallImporter::IntegrityChecker::BodyCheck.new(proposed_payload, publishing_api_content)
      expect(integrity_check.body_text_matches?).to be true
    end

    it "returns no problems even if there is a mismatch in inline atttachment URL filesize" do
      proposed_payload[:details][:body] = "<p>Some other text</p><p><span class=\"gem-c-attachment-link\"><a class=\"govuk-link\" href=\"filename.pdf\" target=\"_blank\">Test File</a> (<span class=\"gem-c-attachment-link__attribute\"><abbr title=\"Portable Document Format\" class=\"gem-c-attachment-link__abbr\">PDF</abbr></span>, <span class=\"gem-c-attachment-link__attribute\">391 KB</span>, <span class=\"gem-c-attachment-link__attribute\">9 pages</span>)</span></p>"
      publishing_api_content[:details][:body] = "<p>Some other text</p><p><span class=\"attachment-inline\"><a href=\"/filename.pdf\">Test File</a> (<span class=\"type\">PDF</span>, <span class=\"file-size\">391KB</span>, <span class=\"page-length\">9 pages</span>)</span></p>"

      integrity_check = WhitehallImporter::IntegrityChecker::BodyCheck.new(proposed_payload, publishing_api_content)
      expect(integrity_check.body_text_matches?).to be true
    end

    it "returns a problem when the body text doesn't match" do
      proposed_payload[:details][:body] = "Some text"
      publishing_api_content[:details][:body] = "Some different text"

      integrity_check = WhitehallImporter::IntegrityChecker::BodyCheck.new(proposed_payload, publishing_api_content)
      expect(integrity_check.body_text_matches?).to be false
    end
  end
end
