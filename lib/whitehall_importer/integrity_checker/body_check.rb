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

      content_publisher_file_size_selector = ".gem-c-attachment-link .gem-c-attachment-link__attribute:nth-of-type(2)"
      whitehall_file_size_selector = ".attachment-inline .file-size, .gem-c-attachment-link .gem-c-attachment-link__attribute:nth-of-type(2)"
      proposed_body_text = remove_html_elements(proposed_body_text, content_publisher_file_size_selector)
      publishing_api_body_text = remove_html_elements(publishing_api_body_text, whitehall_file_size_selector)
      Sanitize.clean(publishing_api_body_text).squish == Sanitize.clean(proposed_body_text).squish
    end

    def remove_html_elements(body, selector)
      doc = Nokogiri.HTML(body)
      doc.search(selector).each do |el|
        el.replace("")
      end
      doc.to_html
    end
  end
end
