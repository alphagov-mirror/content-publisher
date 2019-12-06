# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    name { "John Smith" }
    uid { SecureRandom.uuid }
    email { "someone@example.com" }
    permissions { [User::PRE_RELEASE_FEATURES_PERMISSION] }

    trait :managing_editor do
      permissions { [User::MANAGING_EDITOR_PERMISSION, User::PRE_RELEASE_FEATURES_PERMISSION] }
    end
  end
end
