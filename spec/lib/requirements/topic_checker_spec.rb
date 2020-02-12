RSpec.describe Requirements::TopicChecker do
  include TopicsHelper

  describe "#pre_publish_issues" do
    let(:document_type) { create :document_type, topics: true }
    let(:edition) { create :edition, document_type: document_type }

    it "returns no issues if there are none" do
      edition = create :edition, :publishable
      issues = described_class.new(edition).pre_publish_issues
      expect(issues).to be_empty
    end

    context "when the Publishing API is available" do
      before do
        stub_publishing_api_has_links(
          "content_id" => edition.content_id,
          "links" => {},
          "version" => 3,
        )

        stub_publishing_api_has_taxonomy
      end

      it "returns an issue if there are no topics" do
        issues = described_class.new(edition).pre_publish_issues
        expect(issues).to have_issue(:topics, :none, styles: %i[form summary])
      end
    end

    context "when the Publishing API is down" do
      before do
        stub_publishing_api_isnt_available
      end

      it "returns no issues by default (ignore exception)" do
        issues = described_class.new(edition).pre_publish_issues
        expect(issues.items_for(:topics)).to be_empty
      end

      it "raises an exception if we specify it should" do
        expect { described_class.new(edition).pre_publish_issues(rescue_api_errors: false) }
          .to raise_error GdsApi::BaseError
      end
    end
  end
end
