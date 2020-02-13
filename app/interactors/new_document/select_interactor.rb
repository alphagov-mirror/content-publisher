class NewDocument::SelectInteractor < ApplicationInteractor
  include Rails.application.routes.url_helpers

  delegate :params,
           :user,
           :redirect_url,
           :document_type_selection,
           to: :context

  def call
    find_document_type_selection
    check_for_issues
    find_redirect_url
  end

private

  def find_document_type_selection
    context.document_type_selection = DocumentTypeSelection.find(params[:type])
  end

  def check_for_issues
    issues = Requirements::CheckerIssues.new
    issues.create(:document_type_selection, :not_selected) unless selected_option

    context.fail!(issues: issues) if issues.any?
  end

  def find_redirect_url
    context.redirect_url = if selected_option.subtypes?
                             refine_further_url
                           elsif selected_option.managed_elsewhere?
                             selected_option.managed_elsewhere_url
                           elsif create_document?
                             create_document_url
                           end
  end

  def refine_further_url
    new_document_path(type: selected_option.id)
  end

  def create_document?
    selected_option.type == "document_type"
  end

  def create_document_url
    document = create_document
    create_timeline_entry(document)
    content_path(document)
  end

  def create_document
    CreateDocumentService.call(
      document_type_id: params[:selected_option_id], tags: default_tags, user: user,
    )
  end

  def create_timeline_entry(document)
    TimelineEntry.create_for_status_change(entry_type: :created,
                                           status: document.current_edition.status)
  end

  def default_tags
    user.organisation_content_id ? { primary_publishing_organisation: [user.organisation_content_id] } : {}
  end

  def selected_option
    @selected_option ||= document_type_selection.find_option(params[:selected_option_id])
  end
end
