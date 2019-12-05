# frozen_string_literal: true

module WhitehallImporter
  class CreateImageRevision
    attr_reader :whitehall_image, :filenames

    def self.call(*args)
      new(*args).call
    end

    def initialize(whitehall_image, filenames = [])
      @whitehall_image = whitehall_image
      @filenames = filenames
    end

    def call
      downloaded_file = DownloadFile.call(whitehall_image["url"])
      temp_image = normalise_image(downloaded_file)
      blob_revision = create_blob_revision(temp_image)

      Image::Revision.create!(
        image: Image.new,
        metadata_revision: Image::MetadataRevision.new(
          caption: whitehall_image["caption"],
          alt_text: whitehall_image["alt_text"],
        ),
        blob_revision: blob_revision,
      )
    end

  private

    def create_blob_revision(temp_image)
      ImageBlobService.call(
        temp_image: temp_image,
        filename: UniqueFilenameService.call(
          filenames,
          File.basename(whitehall_image["url"]),
        ),
      )
    end

    def normalise_image(file)
      upload_checker = Requirements::ImageUploadChecker.new(file)
      abort_on_issue(upload_checker.issues)
      normaliser = ImageNormaliser.new(file)
      image = normaliser.normalise
      abort_on_issue(normaliser.issues)

      image
    end

    def abort_on_issue(issues)
      return if issues.empty?

      raise WhitehallImporter::AbortImportError, issues.first.message(style: "form")
    end
  end
end
