# frozen_string_literal: true

RSpec.describe "Import tasks" do
  describe "import:whitehall" do
    let(:whitehall_host) { Plek.new.external_url_for("whitehall-admin") }

    before do
      allow($stdout).to receive(:puts)
      Rake::Task["import:whitehall"].reenable
      stub_request(:get, "#{whitehall_host}/government/admin/export/document/123")
        .to_return(status: 200, body: build(:whitehall_export_document).to_json)
    end

    it "creates a document" do
      allow(WhitehallImporter).to receive(:sync)
      expect { Rake::Task["import:whitehall"].invoke("123") }.to change { Document.count }.by(1)
    end

    it "aborts if the import fails" do
      expect(WhitehallImporter::Import).to receive(:call).and_raise("Error importing")

      expect($stdout).to receive(:puts).with("Import failed")
      expect($stdout).to receive(:puts).with("Error: Error importing")
      expect { Rake::Task["import:whitehall"].invoke("123") }
        .to raise_error(SystemExit)
    end

    it "aborts if the import aborts" do
      expect(WhitehallImporter::Import).to receive(:call).and_raise(
        WhitehallImporter::AbortImportError,
        "Some known error",
      )

      expect($stdout).to receive(:puts).with("Import aborted")
      expect($stdout).to receive(:puts).with("Error: Some known error")
      expect { Rake::Task["import:whitehall"].invoke("123") }
        .to raise_error(SystemExit)
    end

    it "aborts if the sync fails" do
      expect_any_instance_of(ResyncService).to receive(:call).and_raise(
        GdsApi::HTTPTooManyRequests.new(429, "Stoooooopp, too many requests"),
      )

      expect($stdout).to receive(:puts).with("Sync failed")
      expect($stdout).to receive(:puts).with("Error: Stoooooopp, too many requests")
      expect { Rake::Task["import:whitehall"].invoke("123") }
        .to raise_error(SystemExit)
    end

    it "syncs the imported document with publishing-api" do
      document = create(:document, :with_current_and_live_editions)
      allow(Document).to receive(:find_by).and_return(document)

      expect(WhitehallImporter).to receive(:sync).with(anything, document)
      Rake::Task["import:whitehall"].invoke("123")
    end

    it "doesn't sync the imported document if the import fails" do
      allow(WhitehallImporter::Import).to receive(:call).and_raise("Error importing")

      expect(WhitehallImporter).to_not receive(:sync)
      expect { Rake::Task["import:whitehall"].invoke("123") }
        .to raise_error(SystemExit)
    end
  end
end
