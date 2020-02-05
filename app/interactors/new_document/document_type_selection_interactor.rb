# frozen_string_literal: true

class NewDocument::DocumentTypeSelectionInteractor < ApplicationInteractor
  delegate :params,
           :document_type_selection,
           to: :context


  def call
    find_document_type_selection
  end

private

  def find_document_type_selection
    context.document_type_selection = DocumentTypeSelection.find(params[:document_type_selection_id])
  end
end
