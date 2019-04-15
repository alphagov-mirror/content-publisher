# frozen_string_literal: true

class Editions::CreateInteractor
  include Interactor
  delegate :params,
           :user,
           :live_edition,
           :next_edition,
           :draft_current_edition,
           :resume_discarded,
           to: :context

  def call
    Edition.transaction do
      find_and_lock_live_edition
      create_next_edition
      create_timeline_entry
      update_preview
    end
  end

private

  def find_and_lock_live_edition
    edition = Edition.lock.find_current(document: params[:document])
    context.fail!(draft_current_edition: true) unless edition.live?

    context.live_edition = edition
  end

  def create_next_edition
    live_edition.update!(current: false)

    context.resume_discarded = Edition.find_by(
      document: live_edition.document,
      number: live_edition.number + 1,
    )

    context.next_edition = if resume_discarded
                             discarded_edition.resume_discarded(live_edition, user)
                           else
                             Edition.create_next_edition(live_edition, user)
                           end
  end

  def create_timeline_entry
    if resume_discarded
      TimelineEntry.create_for_status_change(entry_type: :draft_reset,
                                             status: next_edition.status)
    else
      TimelineEntry.create_for_status_change(entry_type: :new_edition,
                                             status: next_edition.status)
    end
  end

  def update_preview
    PreviewService.new(live_edition).try_create_preview
  end
end
