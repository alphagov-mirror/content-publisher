class NewDocumentController < ApplicationController
  rescue_from DocumentTypeSelection::NotFoundError do |e|
    raise ActionController::RoutingError, e.message
  end

  def show
    @document_type_selection = DocumentTypeSelection.find(params[:type] || "root")
  end

  def select
    result = NewDocument::SelectInteractor.call(params: params, user: current_user)
    issues, document, redirect_url, document_type_selection, current_selection = result.to_h.values_at(
      :issues,
      :document,
      :redirect_url,
      :document_type_selection,
      :current_selection,
    )

    if issues
      flash.now["requirements"] = { "items" => issues.items }
      render :show,
             assigns: { issues: issues, document_type_selection: document_type_selection },
             status: :unprocessable_entity
    elsif current_selection
      redirect_to show_path(type: current_selection.id)
    elsif redirect_url
      redirect_to redirect_url
    else
      redirect_to content_path(document)
    end
  end
end
