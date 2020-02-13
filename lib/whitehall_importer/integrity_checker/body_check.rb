module WhitehallImporter
  class IntegrityChecker::BodyCheck
    attr_reader :proposed_payload, :publishing_api_content

    def initialize(proposed_payload, publishing_api_content)
      @proposed_payload = proposed_payload
      @publishing_api_content = publishing_api_content
    end

    def body_text_matches?
      proposed_body_text = proposed_payload.dig(:details, :body)
      publishing_api_body_text = publishing_api_content.dig(:details, :body)

      Sanitize.clean(publishing_api_body_text).squish == Sanitize.clean(proposed_body_text).squish
    end
  end
end
