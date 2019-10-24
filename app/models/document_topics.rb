# frozen_string_literal: true

class DocumentTopics
  include ActiveModel::Model

  attr_accessor :document, :version, :topics, :index, :surplus_topics

  def self.find_by_document(document, index)
    publishing_api = GdsApi.publishing_api_v2
    links = publishing_api.get_links(document.content_id)
    topic_content_ids = links.dig("links", "taxons").to_a + ['d1de7e0e-9c04-4c2d-9cc4-f5f0ff04eb50', '8c15b806-ccde-417c-bb40-ce60b711a0b8']

    new(
      index: index,
      document: document,
      version: links["version"],
      topics: topic_list(topic_content_ids, index),
      surplus_topics: topic_content_ids - topic_list(topic_content_ids, index)
    )
  rescue GdsApi::HTTPNotFound
    new(
      index: index,
      document: document,
      version: nil,
      topics: [],
    )
  end

  def patch(topic_content_ids, version)
    topics = topic_content_ids.map { |topic_content_id| Topic.find(topic_content_id, index) }
    self.version = version

    GdsApi.publishing_api_v2.patch_links(
      document.content_id,
      links: {
        taxons: leaf_topic_content_ids(topics),
        topics: legacy_topic_content_ids(topics),
      },
      previous_version: version,
    )
  end

private

  def self.topic_list(topic_content_ids, index)
    topic_content_ids.map { |topic_content_id| Topic.find(topic_content_id, index) unless nil }.compact
  end

  def leaf_topic_content_ids(topics)
    superfluous_topics = topics.map(&:ancestors).flatten
    (topics - superfluous_topics).map(&:content_id)
  end

  def legacy_topic_content_ids(topics)
    breadcrumbs = topics.map(&:breadcrumb).flatten
    breadcrumbs.map(&:legacy_topic_content_ids).flatten.uniq
  end
end
