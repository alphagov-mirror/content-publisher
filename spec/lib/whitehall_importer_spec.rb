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

    context "when the import aborts" do
      before do
        allow(WhitehallImporter::Import).to receive(:call).and_raise(
          WhitehallImporter::AbortImportError,
          message,
        )
      end

      let(:message) { "Import aborted" }

      it "marks the import as aborted and logs the error" do
        record = WhitehallImporter.import(build(:whitehall_export_document))
        expect(record).to be_import_aborted
        expect(record.error_log).to eq(message)
      end
    end
  end

  describe ".sync" do
    it "syncs the imported document with publishing-api" do
      record = WhitehallImporter.import(build(:whitehall_export_document))
      document = Document.find_by(content_id: record.content_id)

      expect(ResyncService).to receive(:call).with(document)
      expect(WhitehallImporter::ClearLinksetLinks).to receive(:call).with(record.content_id)
      WhitehallImporter.sync(record, document)

      expect(record).to be_completed
    end

    context "when the sync fails" do
      before do
        allow_any_instance_of(ResyncService).to receive(:call).and_raise(
          GdsApi::HTTPTooManyRequests.new(429, message),
        )
      end

      let(:message) { "Ahhh too many requests" }

      it "marks the import as failed due to sync issues and logs the error" do
        record = WhitehallImporter.import(build(:whitehall_export_document))
        document = Document.find_by(content_id: record.content_id)
        WhitehallImporter.sync(record, document)

        expect(record).to be_sync_failed
        expect(record.error_log).to eq(message)
      end
    end
  end
end
