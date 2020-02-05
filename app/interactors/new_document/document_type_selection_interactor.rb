# frozen_string_literal: true

class NewDocument::DocumentTypeSelectionInteractor < ApplicationInteractor
  delegate :params,
           :document_type_selection_option,
           to: :context


  def call
    check_for_issues
    find_document_type_selection_option
    # route_the_thing
  end

private

  def check_for_issues
    return if params[:selected_option_id].present?

    context.fail!(issues: document_type_issues)
  end

  def document_type_issues
    Requirements::CheckerIssues.new([
      Requirements::Issue.new(:selected_option_id, :not_selected),
    ])
  end

  def find_document_type_selection_option
    context.document_type_selection_option = DocumentTypeSelection
                                               .find(params[:document_type_selection_id])
                                               .options
                                               .select { |option| option[:id] == params[:selected_option_id] }
  end

  # def route_the_thing
  #   if context.document_type_selection_option["type"] == "refine"
  #   elsif context.document_type_selection_option["type"] == "managed_elsewhere"
  #   elsif context.document_type_selection_option["type"] == "document_type"
  #   end
  # end
end
