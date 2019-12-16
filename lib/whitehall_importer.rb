# frozen_string_literal: true

module WhitehallImporter
  def self.import(whitehall_document)
    record = WhitehallImport.create!(
      whitehall_document_id: whitehall_document["id"],
      payload: whitehall_document,
      content_id: whitehall_document["content_id"],
      state: "importing",
    )

    begin
      Import.call(whitehall_document)
    rescue AbortImportError => e
      record.update!(error_log: e.message,
                    state: "import_aborted")
    rescue StandardError => e
      record.update!(error_log: e.message,
                     state: "import_failed")
    end

    record
  end

  def self.sync(import, document)
    ResyncService.call(document)
    ClearLinksetLinks.call(document.content_id)

    import.update!(state: "completed")
  end
end
