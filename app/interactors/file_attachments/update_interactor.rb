class FileAttachments::UpdateInteractor < ApplicationInteractor
  delegate :params,
           :user,
           :edition,
           :file_attachment_revision,
           to: :context

  def call
    Edition.transaction do
      find_and_lock_edition
      find_file_attachment
      check_for_issues

      update_file_attachment
      update_edition

      create_timeline_entry
      update_preview
    end
  end

private

  def find_and_lock_edition
    context.edition = Edition.lock.find_current(document: params[:document])
    assert_edition_state(edition, &:editable?)
  end

  def find_file_attachment
    context.file_attachment_revision = edition.file_attachment_revisions
                                              .find_by!(file_attachment_id: params[:file_attachment_id])
  end

  def check_for_issues
    checker = Requirements::FileAttachmentMetadataChecker.new(attachment_params)
    issues = checker.pre_update_issues

    context.fail!(issues: issues) if issues.any?
  end

  def update_file_attachment
    updater = Versioning::FileAttachmentRevisionUpdater.new(file_attachment_revision, user)
    revision_attributes = attachment_params.slice(:isbn, :unique_reference)
    updater.assign(revision_attributes)

    context.file_attachment_revision = updater.next_revision
  end

  def update_edition
    updater = Versioning::RevisionUpdater.new(edition.revision, user)
    updater.update_file_attachment(file_attachment_revision)

    context.fail!(unchanged: true) unless updater.changed?

    EditDraftEditionService.call(edition, user, revision: updater.next_revision)
    edition.save!
  end

  def create_timeline_entry
    TimelineEntry.create_for_revision(entry_type: :file_attachment_updated,
                                      edition: edition)
  end

  def update_preview
    FailsafeDraftPreviewService.call(edition)
  end

  def attachment_params
    params.require(:file_attachment).permit(:isbn, :unique_reference)
  end
end
