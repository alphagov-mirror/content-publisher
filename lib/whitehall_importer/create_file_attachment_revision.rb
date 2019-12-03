# frozen_string_literal: true

module WhitehallImporter
  class CreateFileAttachmentRevision
    def self.call(*args)
      new(*args).call
    end

    def initialize(whitehall_file_attachment)
      @whitehall_file_attachment = whitehall_file_attachment
    end

    def call
      DownloadFile.call(whitehall_file_attachment["url"])
    end

  private

    attr_reader :whitehall_file_attachment
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
