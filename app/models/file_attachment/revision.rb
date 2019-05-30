# frozen_string_literal: true

# A File Attachment revision represents an edit of a particular file attachment
#
# This is an immutable model
class FileAttachment::Revision < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :file_attachment, class_name: "FileAttachment"
  belongs_to :metadata_revision, class_name: "FileAttachment::MetadataRevision"
  belongs_to :blob_revision, class_name: "FileAttachment::BlobRevision"

  has_and_belongs_to_many :revisions,
                          class_name: "::Revision",
                          foreign_key: "file_attachment_revision_id",
                          join_table: "revisions_file_attachment_revisions"

  delegate :title, to: :metadata_revision
  delegate :filename,
           :asset,
           :asset_url,
           :assets,
           :ensure_assets,
           :content_type,
           :byte_size,
           :number_of_pages,
           to: :blob_revision

  def readonly?
    !new_record?
  end

  def self.create_initial(blob_attributes:, title:, user:)
    file_attachment = FileAttachment.create!(created_by: user)

    blob_revision = FileAttachment::BlobRevision.create!(
      blob_attributes.merge(created_by: user),
    )

    metadata_revision = FileAttachment::MetadataRevision.create!(created_by: user,
                                                                 title: title)

    FileAttachment::Revision.create!(
      file_attachment: file_attachment,
      created_by: user,
      blob_revision: blob_revision,
      metadata_revision: metadata_revision,
    )
  end
end
