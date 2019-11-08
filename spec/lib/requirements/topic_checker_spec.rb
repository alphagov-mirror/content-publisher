# frozen_string_literal: true

RSpec.describe Requirements::TopicChecker do
  include TopicsHelper

  describe "#pre_publish_issues" do
    it "returns no issues if there are none" do
      document = create(:document, :with_current_edition)

      issues = Requirements::TopicChecker.new(document).pre_publish_issues
      expect(issues).to be_empty
    end

    context "when the Publishing API is available" do
      let(:document_type) { create :document_type, topics: true }
      let(:metadata_revision) { create :metadata_revision, document_type_id: document_type.id }
      let(:revision) { create :revision, metadata_revision: metadata_revision }
      let(:edition) { create :edition, revision: revision }

      before do
        stub_publishing_api_has_links(
          "content_id" => edition.document.content_id,
          "links" => {},
          "version" => 3,
        )

        stub_publishing_api_has_taxonomy
      end

      it "returns an issue if there are no topics" do
        issues = Requirements::TopicChecker.new(edition.document).pre_publish_issues
        expect(issues).to have_issue(:topics, :none, styles: %i[form summary])
      end
    end

    context "when the Publishing API is down" do
      let(:document_type) { create :document_type, topics: true }
      let(:metadata_revision) { create :metadata_revision, document_type_id: document_type.id }
      let(:revision) { create :revision, metadata_revision: metadata_revision }
      let(:edition) { create :edition, revision: revision }

      before do
        stub_publishing_api_isnt_available
      end

      it "returns no issues by default (ignore exception)" do
        issues = Requirements::TopicChecker.new(edition.document).pre_publish_issues
        expect(issues.items_for(:topics)).to be_empty
      end

      it "raises an exception if we specify it should" do
        expect { Requirements::TopicChecker.new(edition.document).pre_publish_issues(rescue_api_errors: false) }
          .to raise_error GdsApi::BaseError
      end
    end
  end
end
