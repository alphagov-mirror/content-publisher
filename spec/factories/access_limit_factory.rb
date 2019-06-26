# frozen_string_literal: true

FactoryBot.define do
  factory :access_limit do
    limit_type { :primary_organisation }
    active { true }
    association :edition
    association :revision_at_creation, factory: :revision
    association :created_by, factory: :user
  end
end
