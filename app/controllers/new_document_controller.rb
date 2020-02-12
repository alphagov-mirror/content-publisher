class NewDocumentController < ApplicationController
  def show
    @document_type_selection = DocumentTypeSelection.find(params[:document_type_selection_id] || "root")
  end

  def select
    result = NewDocument::DocumentTypeSelectionInteractor.call(params: params, user: current_user)
    issues, document, redirect_url, previous_selection, current_selection = result.to_h.values_at(
      :issues,
      :document,
      :redirect_url,
      :previous_selection,
      :current_selection,
    )

    if issues
      flash.now["requirements"] = { "items" => issues.items }
      render :show,
             assigns: { issues: issues, document_type_selection: previous_selection },
             status: :unprocessable_entity
    elsif current_selection
      redirect_to show_path(document_type_selection_id: current_selection.id)
    elsif redirect_url
      redirect_to redirect_url
    else
      redirect_to content_path(document)
    end
  end
end
