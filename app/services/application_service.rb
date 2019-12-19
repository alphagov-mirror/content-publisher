# frozen_string_literal: true

class ApplicationService
  private_class_method :new

  def self.call(*args)
    new(*args).call
  end

protected

  def update_edition_editors(edition, user)
    edition.edition_editors << user unless edition.edition_editors.include? user
  end
end
