# frozen_string_literal: true

class AccessLimit < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true

  belongs_to :edition

  belongs_to :revision_at_creation, class_name: "Revision"

  enum limit_type: { primary_organisation: "primary_organisation",
                     all_organisations: "all_organisations" }

  attr_readonly :limit_type,
                :revision_at_creation_id,
                :edition_id,
                :created_by_id,
                :created_at
end
