RSpec.describe FileAttachments::CreateInteractor do
  describe ".call" do
    before { allow(FailsafeDraftPreviewService).to receive(:call) }

    let(:user) { create(:user) }
    let(:edition) { create(:edition) }
    let(:file) { fixture_file_upload("files/13kb-1-page-attachment.pdf") }
    let(:title) { "My Title" }
    let(:args) do
      {
        params: {
          document: edition.document.to_param,
          file: file,
          title: title,
        },
        user: user,
      }
    end

    context "when input is valid" do
      it "is successful" do
        expect(FileAttachments::CreateInteractor.call(**args)).to be_success
      end

      it "creates a new file attachment revision" do
        expect { FileAttachments::CreateInteractor.call(**args) }
          .to change { FileAttachment::Revision.count }.by(1)
      end

      it "delegates saving the file to the CreateFileAttachmentBlobService" do
        expect(CreateFileAttachmentBlobService).to receive(:call)
          .with(file: file, filename: file.original_filename, user: user)
          .and_call_original
        FileAttachments::CreateInteractor.call(**args)
      end

      it "delegates generating a unique filename to GenerateUniqueFilenameService" do
        expect(GenerateUniqueFilenameService).to receive(:call)
          .with(existing_filenames: edition.revision.file_attachment_revisions.map(&:filename),
                filename: file.original_filename)
          .and_call_original
        FileAttachments::CreateInteractor.call(**args)
      end

      it "sets the title of the File attachment" do
        result = FileAttachments::CreateInteractor.call(**args)
        file_attachment_revision = result.edition.file_attachment_revisions.first
        expect(file_attachment_revision.title).to eq(title)
      end

      it "attributes the various created file attachment models to the user" do
        result = FileAttachments::CreateInteractor.call(**args)
        file_attachment_revision = result.edition.file_attachment_revisions.first

        expect(file_attachment_revision.created_by).to eq(user)
        expect(file_attachment_revision.file_attachment.created_by).to eq(user)
        expect(file_attachment_revision.blob_revision.created_by).to eq(user)
        expect(file_attachment_revision.metadata_revision.created_by).to eq(user)
      end

      it "creates a timeline entry" do
        expect { FileAttachments::CreateInteractor.call(**args) }
          .to change(TimelineEntry, :count).by(1)
      end

      it "updates the preview" do
        expect(FailsafeDraftPreviewService).to receive(:call).with(edition)
        FileAttachments::CreateInteractor.call(**args)
      end
    end

    context "when the edition isn't editable" do
      let(:edition) { create(:edition, :published) }

      it "raises a state error" do
        expect { FileAttachments::CreateInteractor.call(**args) }
          .to raise_error(EditionAssertions::StateError)
      end
    end

    context "when the uploaded file has issues" do
      it "fails with issues returned" do
        checker = instance_double(Requirements::FileAttachmentChecker)
        allow(checker).to receive(:pre_upload_issues).and_return(%w(issue))
        allow(Requirements::FileAttachmentChecker).to receive(:new).and_return(checker)
        result = FileAttachments::CreateInteractor.call(**args)

        expect(result).to be_failure
        expect(result.issues).to eq %w(issue)
      end
    end
  end
end
