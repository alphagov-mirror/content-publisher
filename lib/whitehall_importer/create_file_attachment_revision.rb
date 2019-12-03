# frozen_string_literal: true

module WhitehallImporter
  class CreateFileAttachmentRevision
    def self.call(*args)
      new(*args).call
    end

    def initialize(whitehall_file_attachment, existing_filenames = [])
      @whitehall_file_attachment = whitehall_file_attachment
      @existing_filenames = existing_filenames
    end

    def call
      downloaded_file = DownloadFile.call(whitehall_file_attachment["url"])
      decorated_file = AttachmentFileDecorator.new(downloaded_file, unique_filename)

      create_blob_revision(decorated_file)
    end

  private

    attr_reader :whitehall_file_attachment, :existing_filenames

    def create_blob_revision(file)
      FileAttachmentBlobService.call(
        file: file,
        filename: unique_filename,
      )
    end

    def unique_filename
      @unique_filename ||= UniqueFilenameService.call(
        existing_filenames,
        File.basename(whitehall_file_attachment["url"]),
      )
    end
  end

  class AttachmentFileDecorator < SimpleDelegator
    attr_reader :original_filename

    def initialize(tmp_file, original_filename)
      super(tmp_file)
      @original_filename = original_filename
    end

    def content_type
      nil
    end
  end
end
