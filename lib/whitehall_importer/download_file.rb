# frozen_string_literal: true

module WhitehallImporter
  class DownloadFile
    def self.call(*args)
      new(*args).call
    end

    def initialize(file_url)
      @file_url = file_url
    end

    def call
      file = URI.parse(file_url).open
      if file.is_a?(StringIO)
        # files less than 10 KB return StringIO (we have to manually cast to a tempfile)
        Tempfile.new.tap { |tmp| File.write(tmp.path, file.string) }
      else
        file
      end
    rescue OpenURI::HTTPError
      raise WhitehallImporter::AbortImportError, "File does not exist: #{file_url}"
    end

  private

    attr_reader :file_url
  end
end
