# frozen_string_literal: true

RSpec.describe WhitehallImporter::Import do
  describe ".call" do
    let(:whitehall_user) { build(:whitehall_export_user) }

    it "creates a document" do
      expect { described_class.call(build(:whitehall_migration_document_import)) }
        .to change { Document.count }.by(1)
    end

    it "aborts if a document already exists" do
      content_id = create(:document).content_id
      import_data = build(:whitehall_export_document, content_id: content_id)
      document_import = build(:whitehall_migration_document_import, payload: import_data)
      expect { described_class.call(document_import) }
        .to raise_error(WhitehallImporter::AbortImportError)
    end

    it "sets the document as being imported from Whitehall" do
      document = described_class.call(build(:whitehall_migration_document_import))

      expect(document).to be_imported_from_whitehall
    end

    it "associates the created document with the import record" do
      import_record = build(:whitehall_migration_document_import)
      document = described_class.call(import_record)

      expect(import_record.document).to eq(document)
    end

    it "creates users who have never logged into Content Publisher" do
      import_data = build(:whitehall_export_document, users: [whitehall_user])
      document_import = build(:whitehall_migration_document_import, payload: import_data)
      described_class.call(document_import)
      expect(User.last.attributes).to match hash_including(
        "uid" => whitehall_user["uid"],
        "name" => whitehall_user["name"],
        "email" => whitehall_user["email"],
        "organisation_slug" => whitehall_user["organisation_slug"],
        "organisation_content_id" => whitehall_user["organisation_content_id"],
      )
    end

    it "does not add users who have logged into Content Publisher" do
      User.create!(uid: whitehall_user["uid"])
      import_data = build(:whitehall_export_document, users: [whitehall_user])
      document_import = build(:whitehall_migration_document_import, payload: import_data)

      expect { described_class.call(document_import) }.not_to(change { User.count })
    end

    it "sets created_by_id as the original author" do
      user = User.create!(uid: whitehall_user["uid"])
      edition = build(
        :whitehall_export_edition,
        revision_history: [build(:revision_history_event, whodunnit: whitehall_user["id"])],
      )

      import_data = build(:whitehall_export_document,
                          editions: [edition],
                          users: [whitehall_user])
      document_import = build(:whitehall_migration_document_import, payload: import_data)
      document = described_class.call(document_import)

      expect(document.created_by).to eq(user)
    end

    it "sets current boolean on whether edition is current or not" do
      past_edition = build(
        :whitehall_export_edition,
        created_at: Time.current.yesterday.rfc3339,
        revision_history: [build(:revision_history_event, whodunnit: whitehall_user["id"])],
      )
      current_edition = build(
        :whitehall_export_edition,
        revision_history: [build(:revision_history_event, whodunnit: whitehall_user["id"])],
      )

      import_data = build(:whitehall_export_document,
                          editions: [past_edition, current_edition],
                          users: [whitehall_user])
      document_import = build(:whitehall_migration_document_import, payload: import_data)

      expect(WhitehallImporter::CreateEdition).to receive(:call).with(
        hash_including(current: false),
      ).ordered

      expect(WhitehallImporter::CreateEdition).to receive(:call).with(
        hash_including(current: true),
      ).ordered

      described_class.call(document_import)
    end

    it "sets first_published_at date to publish time of first edition" do
      first_publish_date = Time.current.yesterday.rfc3339
      first_edition = build(
        :whitehall_export_edition,
        revision_history: [
          build(:revision_history_event),
          build(:revision_history_event, event: "update", state: "published", created_at: first_publish_date),
        ],
      )
      second_edition = build(
        :whitehall_export_edition,
        revision_history: [
          build(:revision_history_event),
          build(:revision_history_event, event: "update", state: "published", created_at: Time.current),
        ],
      )

      import_data = build(:whitehall_export_document,
                          editions: [first_edition, second_edition])

      document = described_class.call(import_data)

      expect(document.first_published_at).to eq(first_publish_date)
    end
  end
end
