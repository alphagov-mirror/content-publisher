# frozen_string_literal: true

class ScheduledPublishingJob < ApplicationJob
  # retry at 3s, 18s, 83s, 258s, 627s
  retry_on(StandardError, wait: :exponentially_longer, attempts: 1) do |job, error|
    GovukError.notify(error)
    ScheduledPublishingFailedService.new.call(job.arguments.first)
  end

  discard_and_log(ActiveRecord::RecordNotFound)

  def perform(id)
    edition = nil

    raise "testing scheduled publishing error"

    Edition.transaction do
      edition = Edition.lock.find_current(id: id)
      return unless expected_state?(edition)

      user = edition.status.created_by
      reviewed = edition.status.details.reviewed

      PublishService.new(edition)
                    .publish(user: user, with_review: reviewed)

      TimelineEntry.create_for_status_change(
        entry_type: reviewed ? :scheduled_publishing_succeeded : :scheduled_publishing_without_review_succeeded,
        status: edition.status,
      )
    end

    notify_editors(edition)
  end

private

  def expected_state?(edition)
    unless edition.scheduled?
      Rails.logger.warn("Cannot publish an edition (\##{edition.id}) that is not scheduled")
      return false
    end

    scheduling = edition.status.details

    if scheduling.publish_time > Time.zone.now
      Rails.logger.warn("Cannot publish an edition (\##{edition.id}) scheduled in the future")
      return false
    end

    true
  end

  def notify_editors(edition)
    edition.editors.each do |editor|
      ScheduledPublishMailer.success_email(editor, edition, edition.status)
                            .deliver_later
    end
  end
end
