# frozen_string_literal: true

class AddPublishAtFieldToScheduling < ActiveRecord::Migration[5.2]
  def change
    # This migration has a default value so that we can set it to be nil false
    # and have it not break places where there are already schedulings
    # (integration / dev environments) as scheduling is not a feature used in
    # production this will have no effect there.
    add_column :schedulings, # rubocop:disable Rails/BulkChangeTable
               :publish_at,
               :datetime,
               default: -> { "CURRENT_TIMESTAMP" },
               null: false

    # This sets the column back to a default of nil
    change_column_default :schedulings,
                          :publish_at,
                          from: -> { "CURRENT_TIMESTAMP" },
                          to: nil
  end
end
