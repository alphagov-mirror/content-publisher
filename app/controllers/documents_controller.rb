# frozen_string_literal: true

require "bulk_data_cache"

class DocumentsController < ApplicationController
  def index
    BulkDataCache.fetch(:test)
    BulkDataCache.fetch(:test)
    if filter_params[:filters].empty? && current_user.organisation_content_id
      redirect_to documents_path(organisation: current_user.organisation_content_id)
      return
    end

    filter = EditionFilter.new(current_user, filter_params)
    @editions = filter.editions
    @filter_params = filter.filter_params
    @sort = filter.sort
  end

  def edit
    @edition = Edition.find_current(document: params[:document])
    assert_edition_state(@edition, &:editable?)
    assert_edition_access(@edition, current_user)
    @revision = @edition.revision
  end

  def show
    @edition = Edition.find_current(document: params[:document])
    assert_edition_access(@edition, current_user)
  end

  def confirm_delete_draft
    edition = Edition.find_current(document: params[:document])
    assert_edition_state(edition, &:editable?)
    assert_edition_access(edition, current_user)
    redirect_to document_path(edition.document), confirmation: "documents/show/delete_draft"
  end

  def destroy
    result = Documents::DestroyInteractor.call(params: params, user: current_user)

    if result.api_error
      redirect_to document_path(params[:document]),
                  alert_with_description: t("documents.show.flashes.delete_draft_error")
    else
      redirect_to documents_path
    end
  end

  def update
    result = Documents::UpdateInteractor.call(params: params, user: current_user)
    edition, revision, issues, = result.to_h.values_at(:edition, :revision, :issues)

    if issues
      flash.now["requirements"] = {
        "items" => issues.items(link_options: issues_link_options(edition)),
      }

      render :edit,
             assigns: { edition: edition, revision: revision, issues: issues },
             status: :unprocessable_entity
    elsif params[:submit] == "add_contact"
      redirect_to search_contacts_path(edition.document)
    else
      redirect_to edition.document
    end
  end

  def generate_path
    edition = Edition.find_current(document: params[:document])
    assert_edition_access(edition, current_user)
    base_path = PathGeneratorService.new.path(edition.document, params[:title])
    render plain: base_path
  end

private

  def filter_params
    {
      filters: params.slice(:title_or_url, :document_type, :status, :organisation).permit!,
      sort: params[:sort],
      page: params[:page],
      per_page: 50,
    }
  end

  def issues_link_options(edition)
    format_specific_options = edition.document_type.contents.each_with_object({}) do |field, memo|
      memo[field.id.to_sym] = { href: "##{field.id}-field" }
    end

    {
      title: { href: "#title-field" },
      summary: { href: "#summary-field" },
    }.merge(Hash[format_specific_options])
  end
end
