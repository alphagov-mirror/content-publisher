FactoryBot.define do
  factory :timeline_entry do
    association :created_by, factory: :user
    edition
    entry_type { :created }

    after(:build) do |timeline_entry, evaluator|
      unless timeline_entry.document
        timeline_entry.document = if timeline_entry.edition
                                    timeline_entry.edition.document
                                  else
                                    evaluator.association(:document)
                                  end
      end
    end

    trait :whitehall_imported do
      entry_type { :whitehall_migration }
      transient do
        whitehall_entry_type { :first_created }
        whitehall_entry_contents { {} }
      end

      after(:build) do |timeline_entry, evaluator|
        timeline_entry.details = TimelineEntry::WhitehallImportedEntry.new(
          entry_type: evaluator.whitehall_entry_type,
          contents: evaluator.whitehall_entry_contents,
        )
      end
    end
  end
end
