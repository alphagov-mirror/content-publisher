# frozen_string_literal: true

class NewDocument::DocumentTypeSelectionInteractor < ApplicationInteractor
  delegate :params,
           :user,
           :document_type_id,
           :redirect_url,
           :document,
           :has_subtypes,
           to: :context


  def call
    check_for_issues
    find_selected_document_type

    case selected_option[:type]
    when "subtypes"
      context.has_subtypes = true
    when "managed_elsewhere"
      context.redirect_url = selected_option[:managed_elsewhere_url]
    when "document_type"
      create_document
      create_timeline_entry
    end
  end

private

  def check_for_issues
    return if params[:selected_option_id].present?

    context.fail!(issues: document_type_selection_issues)
  end

  def document_type_selection_issues
    Requirements::CheckerIssues.new([
      Requirements::Issue.new(:selected_option_id, :not_selected),
    ])
  end

  def find_selected_document_type
    context.document_type_id = selected_option[:id]
  end

  def selected_option
    @selected_option ||= DocumentTypeSelection
      .find(params[:document_type_selection_id])
      .options
      .select { |option| option[:id] == params[:selected_option_id] }
      .first
  end

  def create_document
    context.document = CreateDocumentService.call(
      document_type_id: document_type, tags: default_tags, user: user,
    )
  end

  def create_timeline_entry
    TimelineEntry.create_for_status_change(entry_type: :created,
                                           status: document.current_edition.status)
  end

  def document_type
    selected_option[:id]
  end

  def default_tags
    user.organisation_content_id ? { primary_publishing_organisation: [user.organisation_content_id] } : {}
  end
end
