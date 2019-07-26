# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include GDS::SSO::ControllerMethods
  include EditionAssertions

  helper_method :rendering_context

  before_action :authenticate_user!
  before_action { Raven.user_context(id: current_user&.uid) }
  before_action :check_user_access

  add_flash_types :alert_with_description,
                  :alert_with_items,
                  :confirmation,
                  :tried_to_publish,
                  :tried_to_preview

  rescue_from EditionAssertions::StateError do |e|
    Rails.logger.warn(e.message)

    if rendering_context == "modal"
      render nothing: true, status: :bad_request
    elsif e.edition.first? && e.edition.discarded?
      redirect_to documents_path
    else
      redirect_to document_path(e.edition.document)
    end
  end

  def rendering_context
    request.headers["Content-Publisher-Rendering-Context"] || "application"
  end

  def check_user_access
    document_id = request.path_parameters[:document]
    return if document_id.blank?

    access_limit = Edition.find_current(document: document_id)
      .access_limit

    return unless access_limit
      &.organisation_ids
      &.exclude?(current_user.organisation_content_id)

    render "documents/forbidden", status: :forbidden,
      assigns: { edition: access_limit.edition }
  end
end
