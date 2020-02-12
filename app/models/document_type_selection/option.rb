class DocumentTypeSelection::Option
  include InitializeWithHash

  attr_reader :id, :type, :hostname, :path

  def subtypes?
    type == "parent"
  end

  def managed_elsewhere_url
    hostname ? Plek.new.external_url_for(hostname) + path : path
  end

  def managed_elsewhere?
    type == "managed_elsewhere"
  end
end
