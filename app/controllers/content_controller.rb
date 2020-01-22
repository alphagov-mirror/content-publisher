# frozen_string_literal: true

class ContentController < ApplicationController
  def edit
    @edition = Edition.find_current(document: params[:document])
    assert_edition_state(@edition, &:editable?)
    @revision = @edition.revision
  end

  def update
    result = Editions::UpdateInteractor.call(params: params, user: current_user)
    edition, revision, issues, = result.to_h.values_at(:edition, :revision, :issues)

    if issues
      flash.now["requirements"] = {
        "items" => issues.items(link_options: issues_link_options(edition)),
      }

      render :edit,
             assigns: { edition: edition, revision: revision, issues: issues },
             status: :unprocessable_entity
    else
      redirect_to edition.document
    end
  end

private

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
