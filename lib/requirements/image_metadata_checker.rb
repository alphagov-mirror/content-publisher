module Requirements
  class ImageMetadataChecker
    ALT_TEXT_MAX_LENGTH = 125
    CAPTION_MAX_LENGTH = 160
    CREDIT_MAX_LENGTH = 160

    def pre_update_issues(params)
      issues = CheckerIssues.new

      if params[:alt_text].blank?
        issues.create(:image_alt_text, :blank)
      end

      if params[:alt_text].to_s.length > ALT_TEXT_MAX_LENGTH
        issues.create(:image_alt_text, :too_long, max_length: ALT_TEXT_MAX_LENGTH)
      end

      if params[:caption].to_s.length > CAPTION_MAX_LENGTH
        issues.create(:image_caption, :too_long, max_length: CAPTION_MAX_LENGTH)
      end

      if params[:credit].to_s.length > CREDIT_MAX_LENGTH
        issues.create(:image_credit, :too_long, max_length: CREDIT_MAX_LENGTH)
      end

      issues
    end

    def pre_preview_issues(image_revision)
      issues = CheckerIssues.new

      if image_revision.alt_text.blank?
        issues.create(:image_alt_text,
                      :blank,
                      filename: image_revision.filename,
                      image_revision: image_revision)
      end

      issues
    end
  end
end