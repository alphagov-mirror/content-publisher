# frozen_string_literal: true

module IntegrityCheckerHelper
  def problem_message(attribute, expected, actual, plural = false)
    negative_do = plural ? "don't" : "doesn't"
    "#{attribute} #{negative_do} match, expected: #{expected.inspect}, actual: #{actual.inspect}"
  end
end
