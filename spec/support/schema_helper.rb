RSpec::Matchers.define :be_valid_against_schema do |schema_name|
  match do |json|
    schema = JSON.parse(File.read("config/schemas/#{schema_name}.json"))
    validator = JSON::Validator.fully_validate(schema, json)
    validator.empty?
  end
end
