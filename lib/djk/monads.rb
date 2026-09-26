# frozen_string_literal: true

require_relative "monads/version"
require_relative "monads/return_error"
require_relative "monads/result"
require_relative "monads/ok"
require_relative "monads/err"
require_relative "monads/option"

module DJK
  # Rust-style Result and Option monads.
  module Monads
    class Error < StandardError
    end

    ALIASES = %i[ReturnError Err Ok Option Result].freeze
    private_constant :ALIASES

    # Defines ReturnError, Err, Ok, Option, and Result as top level constants, so they can be used without the
    # DJK::Monads namespace.
    #
    # A constant that is already defined at the top level is left untouched, and a warning naming it is printed to
    # stderr. Constants that already point to the matching DJK::Monads class, such as from an earlier call, are skipped
    # without a warning.
    #
    # @return [Array<Symbol>] the names of the constants that were defined by this call
    # @example
    #   DJK::Monads.apply_aliases!
    #   # => [:ReturnError, :Err, :Ok, :Option, :Result]
    #
    #   Result.ok(1)
    #   # => Ok<1>
    def self.apply_aliases!
      defined, undefined = ALIASES.partition { Object.const_defined?(it, false) }
      conflicts = defined.reject { Object.const_get(it, false).equal?(const_get(it)) }
      unless conflicts.empty?
        warn "DJK::Monads.apply_aliases! skipped already defined constants: #{conflicts.join(", ")}", uplevel: 1
      end

      undefined.each { Object.const_set(it, const_get(it)) }
    end
  end
end
