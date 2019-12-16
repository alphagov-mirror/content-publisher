# frozen_string_literal: true

RSpec.describe WhitehallImporter do
  describe ".import" do
    before { allow(WhitehallImporter::Import).to receive(:call) }

    it "creates a WhitehallImport" do
      expect { WhitehallImporter.import(build(:whitehall_export_document)) }
        .to change { WhitehallImport.count }
        .by(1)
    end

    it "imports a document" do
      expect(WhitehallImporter::Import).to receive(:call)
      WhitehallImporter.import(build(:whitehall_export_document))
    end

    it "stores the exported whitehall data" do
      whitehall_export = build(:whitehall_export_document)
      record = WhitehallImporter.import(whitehall_export)
      expect(record.payload).to eq(whitehall_export)
    end

    context "when the import is successful" do
      it "marks the import as completed" do
        record = WhitehallImporter.import(build(:whitehall_export_document))
        expect(record).to be_completed
      end
    end

    context "when the import fails" do
      before do
        allow(WhitehallImporter::Import).to receive(:call).and_raise(TypeError, message)
      end

      let(:message) { "Import failed" }

      it "marks the import as failed and logs the error" do
        record = WhitehallImporter.import(build(:whitehall_export_document))
        expect(record).to be_import_failed
        expect(record.error_log).to eq(message)
      end
    end
  end

  describe ".sync" do
    it "syncs the imported document with publishing-api" do
      record = WhitehallImporter.import(build(:whitehall_export_document))

      expect(ResyncService).to receive(:call).with(record)
      expect(WhitehallImporter::ClearLinksetLinks).to receive(:call).with(record.content_id)
      WhitehallImporter.sync(record)
    end
  end
end
