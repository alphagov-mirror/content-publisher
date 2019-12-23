# frozen_string_literal: true

FactoryBot.define do
  factory :file_attachment_asset, class: FileAttachment::Asset do
    blob_revision { build(:file_attachment_blob_revision) }
  end
end
