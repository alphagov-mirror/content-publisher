class WhitehallImporter::CreateEdition
  SUPPORTED_WHITEHALL_STATES = %w(
      draft
      published
      rejected
      submitted
      superseded
      withdrawn
  ).freeze
  SUPPORTED_LOCALES = %w(en).freeze
  SUPPORTED_DOCUMENT_TYPES = %w(news_story press_release).freeze
  DOCUMENT_SUB_TYPES = %w[
      news_article_type
      publication_type
      corporate_information_page_type
      speech_type
  ].freeze

  def initialize(document:, whitehall_edition:, previous_whitehall_edition:, previous_revision:, user_ids:)
  end

  def call
    check_supported_state
    check_only_in_english

    if unpublished?
      create_unpublished_edition(edition_number)
      create_draft_unpublished_edition
    elsif withdrawn?
      create_withdrawn_edition
    else
      create_regular_edition
    end
  end


private

  def check_supported_state
  end

  def unpublished?(edition)
    edition["unpublishing"] && %w[submitted rejected draft].include?(edition["state"])
  end

  def create_edition(edition_number)
    create_event = create_history_event(whitehall_edition)
    last_event = whitehall_edition["revision_history"].last

    document_type_key = DOCUMENT_SUB_TYPES.reject { |t| whitehall_edition[t].nil? }.first
    raise AbortImportError, "Edition has an unsupported document type" unless SUPPORTED_DOCUMENT_TYPES.include?(whitehall_edition[document_type_key])

    revision = CreateRevision.new(
      status: status, document: document, user_ids: user_ids,
      whitehall_edition: whitehall_edition, previous_whitehall_edition: previous_whitehall_edition).call

    edition = Edition.create!(
      document: document,
      number: edition_number,
      revision_synced: true,
      revision: revision,
      status: initial_status(whitehall_edition, revision),
      current: whitehall_edition["id"] == most_recent_edition["id"],
      live: live?(whitehall_edition),
      created_at: whitehall_edition["created_at"],
      updated_at: whitehall_edition["updated_at"],
      created_by_id: user_ids[create_event["whodunnit"]],
      last_edited_by_id: user_ids[last_event["whodunnit"]],
    )

    set_withdrawn_status(whitehall_edition, edition) if whitehall_edition["state"] == "withdrawn"
  end

  def create_unpublished_edition
  end

  def check_only_in_english
  end

  def create_draft_unpublished_edition
    return if not_applicable?
  end
end
