# frozen_string_literal: true

require_relative "result"

module DJK
  module Monads
    # The failed variant of a Result, wrapping an error.
    #
    # The error can be any object. Calling +unwrap!+ raises it, so an exception or a message string works best.
    #
    # @example
    #   Result.err("boom").unwrap_or(0)
    #   # => 0
    class Err < Result
      # @param error [Object] the error to wrap
      def initialize(error)
        super()
        @error = error
      end

      # @param other [Object] the object to compare against
      # @return [Boolean] true if +other+ is an Err wrapping an error equal to this one
      def ==(other)
        return false unless other.is_a?(Result) && other.err?

        error == other.unwrap_err!
      end

      # @return [Array(Object)] the wrapped error in a single element array
      def deconstruct
        [error]
      end

      # @param _keys [Array<Symbol>, nil] ignored, every key is always returned
      # @return [Hash{Symbol => Object}] the wrapped error under +:error+
      def deconstruct_keys(_keys)
        { error: }
      end

      # @return [Boolean] always true
      def err?
        true
      end

      # Collapses nested results, returning the innermost one.
      #
      # @return [Result] the innermost result when the error is a Result, otherwise +self+
      def flatten
        return self unless error.is_a?(Result)

        error.flatten
      end

      # Does nothing, since there is no value to chain from.
      #
      # @return [Err] +self+, without calling the block
      def flat_map(&)
        self
      end

      # Chains another result producing operation onto the wrapped error.
      #
      # @yieldparam error [Object] the wrapped error
      # @yieldreturn [Result] must return a Result
      # @raise [ReturnError] when the block does not return a Result
      # @return [Result] the result returned by the block
      def flat_map_err
        yield(error).tap { raise ReturnError, "block must return a Result" unless it.is_a?(Result) }
      end

      # @return [String] the inspected error wrapped in <tt>Err<></tt>, such as <tt>Err<"boom"></tt>
      def inspect
        "Err<#{error.inspect}>"
      end

      # Does nothing, since there is no value to transform.
      #
      # @return [Err] +self+, without calling the block
      def map
        self
      end

      # Transforms the wrapped error.
      #
      # @yieldparam error [Object] the wrapped error
      # @return [Err] an Err wrapping the block's return value, which is not flattened when it is itself a Result
      def map_err
        Result.err(yield(error))
      end

      # @return [Boolean] always false
      def ok?
        false
      end

      # Runs the block with the wrapped error for its side effects.
      #
      # @yieldparam error [Object] the wrapped error
      # @return [Err] +self+, ignoring the block's return value
      def on_err
        yield error
        self
      end

      # Does nothing, since there is no value.
      #
      # @return [Err] +self+, without calling the block
      def on_ok
        self
      end

      # @return [Hash{Symbol => Object}] the +:err+ variant along with the wrapped error
      def to_h
        { variant: :err, error: }
      end

      # Always raises the wrapped error, since there is no value to unwrap.
      #
      # An exception is raised as is, and a string is raised as a RuntimeError with that message. Any other object
      # makes +raise+ fail with a TypeError.
      #
      # @raise [Exception] the wrapped error
      def unwrap!
        raise error
      end

      # @return [Object] the wrapped error
      def unwrap_err!
        error
      end

      # @param default [Object] the value to return
      # @return [Object] +default+
      def unwrap_or(default)
        default
      end

      # @yieldparam error [Object] the wrapped error
      # @return [Object] the block's return value
      def unwrap_or_else
        yield error
      end

      private

      attr_reader :error
    end
  end
end
