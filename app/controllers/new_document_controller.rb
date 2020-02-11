# frozen_string_literal: true

class NewDocumentController < ApplicationController
  def show
    @document_type_selection = DocumentTypeSelection.find(params[:selected_option_id] || "root")
  end

  def select
    result = NewDocument::DocumentTypeSelectionInteractor.call(params: params, user: current_user)
    issues, document, redirect_url, needs_refining, previous_selection, current_selection = result.to_h.values_at(
      :issues,
      :document,
      :redirect_url,
      :needs_refining,
      :previous_selection,
      :current_selection,
    )

    if issues
      flash.now["requirements"] = { "items" => issues.items }
      render :show,
             assigns: { issues: issues, document_type_selection: previous_selection },
             status: :unprocessable_entity
    elsif needs_refining
      render :show,
             assigns: { issues: issues, document_type_selection: current_selection }
    elsif redirect_url
      redirect_to redirect_url
    else
      redirect_to content_path(document)
    end
  end
end
