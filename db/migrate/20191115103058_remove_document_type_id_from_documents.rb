# frozen_string_literal: true

class RemoveDocumentTypeIdFromDocuments < ActiveRecord::Migration[5.2]
  def up
    remove_column :documents, :document_type_id
  end

  def down
    add_column :documents, :document_type_id, :string
  end
end
