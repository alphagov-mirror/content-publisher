# frozen_string_literal: true

class WhitehallDocumentImportJob < ApplicationJob
  discard_on(StandardError) do |job, error|
    document_import = job.arguments.first
    handle_error(document_import, error)
  end

  # retry at 3s, 18s, 83s, 258s, 627s
  retry_on(GdsApi::BaseError, attempts: 5, wait: :exponentially_longer) do |job, error|
    document_import = job.arguments.first
    handle_error(document_import, error)
  end

  def perform(document_import)
    document_import = WhitehallImporter::Import.call(document_import)
    document_import = WhitehallImporter::Sync.call(document_import)
    document_import.whitehall_migration&.check_migration_finished
  end

  def self.handle_error(document_import, error)
    errors = [error.inspect]

    if document_import.pending?
      begin
        GdsApi.whitehall_export.unlock_document(document_import.whitehall_document_id)
      rescue GdsApi::BaseError => e
        errors << e.inspect
      end
    end

    error_log = errors.join(", ")

    case error
    when WhitehallImporter::IntegrityCheckError
      document_import.update!(
        error_log: error_log,
        state: "import_aborted",
        integrity_check_problems: error.problems,
        integrity_check_proposed_payload: error.payload,
      )
    when WhitehallImporter::AbortImportError
      document_import.update!(state: "import_aborted", error_log: error_log)
    else
      state = document_import.imported? ? "sync_failed" : "import_failed"
      document_import.update!(state: state, error_log: error_log)
    end
  end
end
