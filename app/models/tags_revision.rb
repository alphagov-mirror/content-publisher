# frozen_string_literal: true

# This stores the tags of a revision, which are grouped associations to other
# GOV.UK content by a particular tag (such as organisations).
#
# This model is immutable.
class TagsRevision < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true

  scope :tag_contains, ->(tag, value) do
    where("exists(
      select 1
      from json_array_elements(tags_revisions.tags->:tag)
      where array_to_json(array[value])->>0 = :value
    )", tag: tag, value: value)
  end

  scope :primary_organisation, ->(organisation_id) do
    tag_contains(:primary_publishing_organisation, organisation_id)
  end

  scope :tagged_organisations, ->(organisation_id) do
    tag_contains(:primary_publishing_organisation, organisation_id)
      .or(tag_contains(:organisations, organisation_id))
  end

  def readonly?
    !new_record?
  end

  def primary_publishing_organisation_id
    tags["primary_publishing_organisation"].to_a.first
  end

  def supporting_organisation_ids
    tags["organisations"].to_a
  end
end
