RSpec.describe Requirements::FileAttachmentChecker do
  describe "#pre_upload_issues" do
    it "returns no issues if there are none" do
      file = fixture_file_upload("files/text-file-74bytes.txt", "text/plain")
      issues = described_class.new(file: file, title: "Cool title").pre_upload_issues
      expect(issues).to be_empty
    end

    it "returns no upload issues for a text file when it has no extension" do
      file = fixture_file_upload("files/no_extension", "text/plain")
      issues = described_class.new(file: file, title: nil).pre_upload_issues
      expect(issues.items_for(:file_attachment_upload)).to be_empty
    end

    it "returns no upload issues when a zip file contains supported file types" do
      file = fixture_file_upload("files/valid_zip.zip", "application/zip")
      issues = described_class.new(file: file, title: nil).pre_upload_issues
      expect(issues.items_for(:file_attachment_upload)).to be_empty
    end

    it "returns an issue when there is no title" do
      issues = described_class.new(file: nil, title: "").pre_upload_issues
      expect(issues).to have_issue(:file_attachment_title, :blank)
    end

    it "returns an issue when the title is too long" do
      max_length = Requirements::FileAttachmentChecker::TITLE_MAX_LENGTH
      title = "z" * (max_length + 1)
      issues = described_class.new(file: nil, title: title).pre_upload_issues
      expect(issues).to have_issue(:file_attachment_title, :too_long, max_length: max_length)
    end

    it "returns an issue when no file_attachment is specified" do
      issues = described_class.new(file: nil, title: "Cool title").pre_upload_issues
      expect(issues).to have_issue(:file_attachment_upload, :no_file)
    end

    it "returns an issue when the file type is not supported" do
      file = fixture_file_upload("files/bad_file.rb", "application/x-ruby")
      issues = described_class.new(file: file, title: "Cool title").pre_upload_issues
      expect(issues).to have_issue(:file_attachment_upload, :unsupported_type)
    end

    it "returns an issue when the zip file contains unsupported file types" do
      file = fixture_file_upload("files/unsupported_type_in_zip.zip", "application/zip")
      issues = described_class.new(file: file, title: "Cool title").pre_upload_issues
      expect(issues).to have_issue(:file_attachment_upload, :zip_unsupported_type)
    end
  end

  describe "#pre_update_issues" do
    it "returns no issues if there are none" do
      file = fixture_file_upload("files/text-file-74bytes.txt", "text/plain")
      issues = described_class.new(file: file, title: "Cool title").pre_update_issues
      expect(issues).to be_empty
    end

    it "returns title issues when only the title is provided" do
      max_length = Requirements::FileAttachmentChecker::TITLE_MAX_LENGTH
      title = "z" * (max_length + 1)
      issues = described_class.new(title: title).pre_update_issues
      expect(issues).to have_issue(:file_attachment_title, :too_long, max_length: max_length)
      expect(issues.items_for(:file_attachment_upload)).to be_empty
    end
  end
end
