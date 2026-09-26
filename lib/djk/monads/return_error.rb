# frozen_string_literal: true

module DJK
  module Monads
    # Raised when a method or block does not return an expected value.
    class ReturnError < StandardError
    end
  end
end
