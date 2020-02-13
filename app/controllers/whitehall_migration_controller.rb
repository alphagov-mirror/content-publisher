class WhitehallMigrationController < ApplicationController
  before_action { authorise_user!(User::DEBUG_PERMISSION) }

  def show
    @whitehall_migration = whitehall_migration
  end

  def documents
    @documents = whitehall_migration.document_imports
  end

  def document
    @document = whitehall_migration
                .document_imports
                .find(params[:document_import_id])
  end

private

  def whitehall_migration
    WhitehallMigration.find(params[:migration_id])
  end
end
