class PreviewAssetService::Payload
  attr_reader :edition

  def initialize(edition)
    @edition = edition
  end

  def for_update
    payload = { draft: true, auth_bypass_ids: [edition.auth_bypass_id] }

    if edition.access_limit
      org_ids = edition.access_limit_organisation_ids
      payload[:access_limited_organisation_ids] = org_ids
    end

    payload
  end

  def for_upload(asset)
    for_update.merge(
      file: PreviewAssetService::UploadedFile.new(asset),
      content_type: asset.content_type,
    )
  end
end
