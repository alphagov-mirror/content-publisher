# frozen_string_literal: true

# Represents all versions of a piece of content in a particular locale.
# The version of content that is draft or been on GOV.UK is represented as an
# edition model. Each edit a user has made to content is represented through a
# revision model on an edition.
#
# This model is mutable
class Document < ApplicationRecord
  attr_readonly :content_id, :locale, :document_type_id

  belongs_to :created_by, class_name: "User", optional: true

  has_one :current_edition,
          -> { where(current: true) },
          class_name: "Edition",
          inverse_of: :document

  has_one :live_edition,
          -> { where(live: true) },
          class_name: "Edition",
          inverse_of: :document

  has_many :editions

  has_many :revisions

  has_many :timeline_entries

  delegate :topics, to: :document_topics

  scope :using_base_path, ->(base_path) do
    left_outer_joins(current_edition: { revision: :content_revision },
                     live_edition: { revision: :content_revision })
      .where("content_revisions.base_path": base_path)
  end

  def self.access_current_edition?(param, user)
    content_id, locale = param.split(":")

    document_criteria = { content_id: content_id, locale: locale }

    unless Document.joins(:current_edition).exists?(document_criteria)
      raise ActiveRecord::RecordNotFound,
            "Cannot find current edition for content_id=#{content_id} locale=#{locale}"
    end

    Edition.can_access(user)
           .joins(:document)
           .exists?(current: true, documents: document_criteria)
  end

  def self.find_by_param(content_id_and_locale)
    content_id, locale = content_id_and_locale.split(":")
    find_by!(content_id: content_id, locale: locale)
  end

  def self.create_initial(content_id: SecureRandom.uuid,
                          document_type_id:,
                          locale: "en",
                          user: nil,
                          tags: {})
    transaction do
      document = create!(content_id: content_id,
                         locale: locale,
                         document_type_id: document_type_id,
                         created_by: user)

      document.tap { |d| Edition.create_initial(d, user, tags) }
    end
  end

  def next_edition_number
    (editions.maximum(:number) || 0) + 1
  end

  def next_revision_number
    (revisions.maximum(:number) || 0) + 1
  end

  def to_param
    content_id + ":" + locale
  end

  def document_type
    DocumentType.find(document_type_id)
  end

  def document_topics
    @document_topics_index ||= TopicIndexService.new
    DocumentTopics.find_by_document(self, @document_topics_index)
  end

  def newly_created?
    return false if !current_edition || !current_edition.first?

    current_edition.created_at == current_edition.updated_at
  end
end
