# frozen_string_literal: true

require "rspec/expectations"

RSpec::Matchers.define :be_ok_result do
  match { |actual| actual.is_a?(DJK::Monads::Ok) }

  failure_message { |actual| "expected #{actual.inspect} to be an Ok result" }

  failure_message_when_negated { |actual| "expected #{actual.inspect} not to be an Ok result" }
end

RSpec::Matchers.define :be_err_result do |expected_class = nil|
  match { |actual| actual.is_a?(DJK::Monads::Err) && (expected_class.nil? || actual.unwrap_err!.is_a?(expected_class)) }

  failure_message do |actual|
    if expected_class.nil?
      "expected #{actual.inspect} to be an Err result"
    elsif actual.is_a?(DJK::Monads::Err)
      "expected #{actual.inspect} to be an Err result of type #{expected_class}, but got #{actual.unwrap_err!.class}"
    else
      "expected #{actual.inspect} to be an Err result of type #{expected_class}"
    end
  end

  failure_message_when_negated do |actual|
    if expected_class
      "expected #{actual.inspect} not to be an Err result of type #{expected_class}"
    else
      "expected #{actual.inspect} not to be an Err result"
    end
  end
end
