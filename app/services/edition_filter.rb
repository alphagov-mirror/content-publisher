# frozen_string_literal: true

class EditionFilter
  include ActiveRecord::Sanitization::ClassMethods

  SORT_KEYS = %w[last_updated].freeze
  DEFAULT_SORT = "-last_updated"

  attr_reader :filters, :sort, :page, :per_page, :user

  def initialize(user, **params)
    @filters = params[:filters].to_h.symbolize_keys
    @sort = allowed_sort?(params[:sort]) ? params[:sort] : DEFAULT_SORT
    @page = params.fetch(:page, 1).to_i
    @per_page = params[:per_page]
    @user = user
  end

  def editions
    revision_joins = { revision: %i[content_revision tags_revision] }
    scope = Edition.where(current: true)
                   .can_access(user)
                   .joins(revision_joins, :status, :document)
                   .preload(revision_joins, :status, :document, :last_edited_by)
    scope = filtered_scope(scope)
    scope = ordered_scope(scope)
    scope.page(page).per(per_page)
  end

  def filter_params
    filters.dup.tap do |params|
      params[:sort] = sort if sort != DEFAULT_SORT
      params[:page] = page if page > 1
    end
  end

private

  def allowed_sort?(sort)
    SORT_KEYS.flat_map { |item| [item, "-#{item}"] }.include?(sort)
  end

  def filtered_scope(scope)
    filters.inject(scope) do |memo, (field, value)|
      next memo if value.blank?

      case field
      when :title_or_url
        memo.where("content_revisions.title ILIKE ? OR content_revisions.base_path ILIKE ?",
                   "%#{sanitize_sql_like(value)}%",
                   "%#{sanitize_sql_like(value)}%")
      when :document_type
        memo.where("documents.document_type_id": value)
      when :status
        if value == "published"
          memo.where("statuses.state": %w[published published_but_needs_2i])
        else
          memo.where("statuses.state": value)
        end
      when :organisation
        tags = TagsRevision.tag_contains(:primary_publishing_organisation, value)
                           .or(TagsRevision.tag_contains(:organisations, value))
        memo.merge(tags)
      else
        memo
      end
    end
  end

  def ordered_scope(scope)
    direction = sort.chars.first == "-" ? :desc : :asc
    case sort.delete_prefix("-")
    when "last_updated"
      scope.order("editions.last_edited_at #{direction}")
    else
      scope
    end
  end
end
