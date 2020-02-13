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

    it "returns a problem when the body text doesn't match" do
      proposed_payload[:details][:body] = "Some text"
      publishing_api_content[:details][:body] = "Some different text"

      integrity_check = WhitehallImporter::IntegrityChecker::BodyCheck.new(proposed_payload, publishing_api_content)
      expect(integrity_check.body_text_matches?).to be false
    end
  end
end
