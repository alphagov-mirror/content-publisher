# frozen_string_literal: true

module WhitehallImporter
  class Import
    attr_reader :document_import, :whitehall_document

    def self.call(*args)
      new(*args).call
    end

    def initialize(document_import)
      @document_import = document_import
      @whitehall_document = document_import.payload
    end

    def call
      ActiveRecord::Base.transaction do
        user_ids = create_users(whitehall_document["users"])
        document_import.update!(document: create_document(user_ids))

        whitehall_document["editions"].each_with_index do |edition, edition_number|
          CreateEdition.call(
            document_import: document_import,
            current: current?(edition),
            whitehall_edition: edition,
            edition_number: edition_number + 1,
            user_ids: user_ids,
          )
        end

        document_import.document
      end
    end

  private

    def current?(edition)
      edition["id"] == whitehall_document["editions"].max_by { |e| e["created_at"] }["id"]
    end

    def create_users(users)
      users.each_with_object({}) do |user, memo|
        user_keys = %w[uid name email organisation_slug organisation_content_id]
        attributes = user.slice(*user_keys).merge("permissions" => [])
        user_object = User.find_by(uid: user["uid"]) || User.create!(attributes)
        memo[user["id"]] = user_object.id
      end
    end

    def create_document(user_ids)
      content_id = whitehall_document["content_id"]
      if Document.exists?(content_id: content_id)
        raise AbortImportError, "Document with content_id #{content_id} already exists"
      end

      event = first_edition_history.create_event!

      Document.create!(
        content_id: content_id,
        locale: "en",
        created_at: whitehall_document["created_at"],
        updated_at: whitehall_document["updated_at"],
        created_by_id: user_ids[event["whodunnit"]],
        first_published_at: first_publish_date,
        imported_from: "whitehall",
      )
    end

    def first_publish_date
      first_publish_event = first_edition_history.first_state_event("published") || {}
      first_publish_event["created_at"]
    end

    def first_edition_history
      EditionHistory.new(whitehall_document["editions"].first["revision_history"])
    end
  end
end
