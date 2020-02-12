RSpec.describe Editions::CreateInteractor do
  describe ".call" do
    let(:user) { create :user }

    before do
      populate_default_government_bulk_data
      stub_any_publishing_api_put_content
    end

    it "resets the edition metadata" do
      edition = create(:edition,
                       live: true,
                       change_note: "note",
                       proposed_publish_time: Time.current,
                       update_type: :minor)

      params = { document: edition.document.to_param }

      next_edition = described_class
        .call(params: params, user: user)
        .next_edition

      expect(next_edition.update_type).to eq "major"
      expect(next_edition.change_note).to be_empty
      expect(next_edition.proposed_publish_time).to be_nil
      expect(next_edition).to be_draft
      expect(next_edition).to be_current
    end

    it "sends a preview of the new edition to the Publishing API" do
      old_edition = create(:edition, :published)

      expect(FailsafeDraftPreviewService).to receive(:call)
      expect(FailsafeDraftPreviewService).not_to receive(:call).with(old_edition)

      described_class
        .call(params: { document: old_edition.document.to_param }, user: user)
    end

    context "when the edition was discarded" do
      let(:live_edition) { create(:edition, :published) }
      let(:params) { { document: live_edition.document.to_param } }

      let!(:edition) do
        create(:edition,
               state: "discarded",
               current: false,
               document: live_edition.document)
      end

      it "resumes the edition" do
        next_edition = described_class
          .call(params: params, user: user)
          .next_edition

        expect(next_edition.number).to eq edition.number
        expect(next_edition).to eq edition.reload
      end

      it "creates a timeline entry" do
        next_edition = described_class
          .call(params: params, user: user)
          .next_edition

        entry = TimelineEntry.last
        expect(entry.entry_type).to eq "draft_reset"
        expect(entry.status).to eq next_edition.status
      end
    end

    context "when the edition is live" do
      let(:edition) { create(:edition, live: true, number: 2) }
      let(:params) { { document: edition.document.to_param } }

      it "creates a new edition" do
        next_edition = described_class
          .call(params: params, user: user)
          .next_edition

        expect(next_edition).not_to eq edition.reload
        expect(next_edition.number).to eq 3
        expect(next_edition.created_by).to eq user
      end

      it "creates a timeline entry" do
        next_edition = described_class
          .call(params: params, user: user)
          .next_edition

        entry = TimelineEntry.last
        expect(entry.entry_type).to eq "new_edition"
        expect(entry.status).to eq next_edition.status
      end
    end
  end
end
