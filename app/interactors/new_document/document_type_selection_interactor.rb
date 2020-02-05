# frozen_string_literal: true

class NewDocument::DocumentTypeSelectionInteractor < ApplicationInteractor
  delegate :params,
           :document_type_selection,
           to: :context


  def call
    check_for_issues
    find_document_type_selection
  end

private

  def check_for_issues
    return if params[:document_type_selection_id].present?

    context.fail!(issues: document_type_issues)
  end

  def document_type_issues
    Requirements::CheckerIssues.new([
      Requirements::Issue.new(:document_type_selection_id, :not_selected),
    ])
  end

  def find_document_type_selection
    context.document_type_selection = DocumentTypeSelection.find(params[:document_type_selection_id])
  end
end
