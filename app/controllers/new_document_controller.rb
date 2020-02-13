class NewDocumentController < ApplicationController
  rescue_from DocumentTypeSelection::NotFoundError do |e|
    raise ActionController::RoutingError, e.message
  end

  def show
    @document_type_selection = DocumentTypeSelection.find(params[:type] || "root")
  end

  def select
    result = NewDocument::SelectInteractor.call(params: params, user: current_user)
    issues, redirect_url, document_type_selection = result.to_h.values_at(:issues,
                                                                          :redirect_url,
                                                                          :document_type_selection)

    if issues
      flash.now["requirements"] = { "items" => issues.items }
      render :show,
             assigns: { issues: issues, document_type_selection: document_type_selection },
             status: :unprocessable_entity
    else
      redirect_to redirect_url
    end
  end
end
