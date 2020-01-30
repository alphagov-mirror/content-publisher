# frozen_string_literal: true

class DocumentType::TitleAndBasePathField
  TITLE_MAX_LENGTH = 300

  def id
    "title_and_base_path"
  end

  def payload(edition)
    {
      base_path: edition.base_path,
      title: edition.title,
      routes: [
        { path: edition.base_path, type: "exact" },
      ],
    }
  end

  def updater_params(edition, params)
    title = params.require(:revision)[:title]&.strip
    base_path = GenerateBasePathService.call(edition.document, title)
    { title: title, base_path: base_path }
  end

  def pre_update_issues(edition, revision)
    issues = Requirements::CheckerIssues.new

    begin
      if base_path_conflict?(edition, revision)
        issues << Requirements::Issue.new(:title, :conflict)
      end
    rescue GdsApi::BaseError => e
      GovukError.notify(e)
    end

    issues + pre_preview_issues(edition, revision)
  end

  def pre_preview_issues(_edition, revision)
    issues = Requirements::CheckerIssues.new

    if revision.title.blank?
      issues << Requirements::Issue.new(:title, :blank)
    end

    if revision.title.to_s.size > TITLE_MAX_LENGTH
      issues << Requirements::Issue.new(:title, :too_long, max_length: TITLE_MAX_LENGTH)
    end

    if revision.title.to_s.lines.count > 1
      issues << Requirements::Issue.new(:title, :multiline)
    end

    issues
  end

  def pre_publish_issues(_edition, _revision)
    Requirements::CheckerIssues.new
  end

private

  def base_path_conflict?(edition, revision)
    return false unless edition.document_type.check_path_conflict

    base_path_owner = GdsApi.publishing_api.lookup_content_id(
      base_path: revision.base_path,
      with_drafts: true,
      exclude_document_types: [],
      exclude_unpublishing_types: [],
    )

    base_path_owner && base_path_owner != edition.content_id
  end
end
