# frozen_string_literal: true

class WhitehallImporter::CreateFileAttachmentRevision
  def self.call(*args)
    new(*args).call
  end

  def initialize(whitehall_file_attachment)
    @whitehall_file_attachment = whitehall_file_attachment
  end

  def call
    download_file
  end

private

  attr_reader :whitehall_file_attachment

  def download_file
    file = URI.parse(whitehall_file_attachment["url"]).open
    if file.is_a?(StringIO)
      # files less than 10 KB return StringIO (we have to manually cast to a tempfile)
      Tempfile.new.tap { |tmp| File.write(tmp.path, file.string) }
    else
      file
    end
  rescue OpenURI::HTTPError
    raise AbortFileAttachmentError, "File attachment does not exist: #{whitehall_file_attachment['url']}"
  end
end

class AbortFileAttachmentError < RuntimeError
  def initialize(message)
    super(message)
  end
end
