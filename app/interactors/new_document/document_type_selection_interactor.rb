class NewDocument::DocumentTypeSelectionInteractor < ApplicationInteractor
  delegate :params,
           :user,
           :redirect_url,
           :document,
           :current_selection,
           :previous_selection,
           to: :context

  def call
    find_previous_selection
    check_for_issues
    find_current_selection
    find_redirect_url

    if create_document?
      create_document
      create_timeline_entry
    end
  end

private

  def find_previous_selection
    context.previous_selection = DocumentTypeSelection.find(params[:document_type_selection_id])
  end

  def check_for_issues
    issues = Requirements::CheckerIssues.new
    issues.create(:document_type_selection, :not_selected) if params[:selected_option_id].blank?
    context.fail!(issues: issues) if issues.any?
  end

  def find_current_selection
    return unless selected_option.subtypes?

    context.current_selection = DocumentTypeSelection.find(params[:selected_option_id])
  end

  def find_redirect_url
    context.redirect_url = selected_option.managed_elsewhere_url
  end

  def create_document?
    selected_option.type == "document_type"
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

  def selected_option
    @selected_option ||= previous_selection
      .options
      .select { |option| option.id == params[:selected_option_id] }
      .first
  end
end
