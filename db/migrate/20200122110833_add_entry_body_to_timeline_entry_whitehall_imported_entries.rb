class AddEntryBodyToTimelineEntryWhitehallImportedEntries < ActiveRecord::Migration[6.0]
  def change
    add_column :timeline_entry_whitehall_imported_entries, :entry_body, :json
  end
end
