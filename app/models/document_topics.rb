# frozen_string_literal: true

class DocumentTopics
  include ActiveModel::Model

  attr_accessor :document, :version, :topic_content_ids, :index

  def self.find_by_document(document, index)
    publishing_api = GdsApi.publishing_api_v2
    links = publishing_api.get_links(document.content_id)

    new(
      index: index,
      document: document,
      version: links["version"],
      topic_content_ids: links.dig("links", "taxons").to_a,
    )
  rescue GdsApi::HTTPNotFound
    new(
      index: index,
      document: document,
      version: nil,
      topic_content_ids: [],
    )
  end

  def patch(updated_topic_content_ids, version)
    new_topic_content_ids = valid_topic_content_ids(updated_topic_content_ids) + unknown_taxon_content_ids

    update_self(new_topic_content_ids, version)

    GdsApi.publishing_api_v2.patch_links(
      document.content_id,
      links: {
        taxons: leaf_topic_content_ids + unknown_taxon_content_ids,
        topics: legacy_topic_content_ids,
      },
      previous_version: version,
    )
  end

  def topics
    @topics ||= topic_content_ids.map { |topic_content_id| Topic.find(topic_content_id, index) }.compact
  end

private

  def leaf_topic_content_ids
    superfluous_topics = topics.map(&:ancestors).flatten
    (topics - superfluous_topics).map(&:content_id)
  end

  def legacy_topic_content_ids
    breadcrumbs = topics.map(&:breadcrumb).flatten
    breadcrumbs.map(&:legacy_topic_content_ids).flatten.uniq
  end

  def unknown_taxon_content_ids
    @unknown_taxon_content_ids ||= topic_content_ids.reject { |topic_content_id| index.lookup(topic_content_id) }
  end

  def valid_topic_content_ids(topic_content_ids)
    topic_content_ids.select { |topic_content_id| index.lookup(topic_content_id) }
  end

  def update_self(topic_content_ids, version)
    self.topic_content_ids = topic_content_ids
    self.version = version
    @topics = nil
  end
end
