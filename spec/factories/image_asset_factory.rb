# frozen_string_literal: true

FactoryBot.define do
  factory :image_asset, class: Image::Asset do
    blob_revision { build(:image_blob_revision, ensure_assets: false) }
    variant { "960" }
  end
end
