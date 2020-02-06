# frozen_string_literal: true

class NewDocument::DocumentTypeSelectionInteractor < ApplicationInteractor
  delegate :params,
           :user,
           :redirect_url,
           :document,
           :needs_refining,
           to: :context


  def call
    check_for_issues
    check_for_subtypes
    find_redirect_url

    if create_document?
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

  def check_for_subtypes
    context.needs_refining = true if selected_option.subtypes?
  end

  def find_redirect_url
    context.redirect_url = selected_option.managed_elsewhere_url
  end

  def create_document?
    selected_option.type == "document_type"
  end

  def selected_option
    @selected_option ||= DocumentTypeSelection
      .find(params[:document_type_selection_id])
      .options
      .select { |option| option.id == params[:selected_option_id] }
      .first
  end

  def create_document
    context.document = CreateDocumentService.call(
      document_type_id: params[:selected_option_id], tags: default_tags, user: user,
    )
  end

  def create_timeline_entry
    TimelineEntry.create_for_status_change(entry_type: :created,
                                           status: document.current_edition.status)
  end

  def default_tags
    user.organisation_content_id ? { primary_publishing_organisation: [user.organisation_content_id] } : {}
  end
end
