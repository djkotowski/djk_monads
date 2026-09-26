# frozen_string_literal: true

require_relative "result"

module DJK
  module Monads
    # The successful variant of a Result, wrapping a value.
    #
    # @example
    #   Result.ok(1).unwrap!
    #   # => 1
    class Ok < Result
      # @param value [Object] the value to wrap
      def initialize(value)
        super()
        @value = value
      end

      # @param other [Object] the object to compare against
      # @return [Boolean] true if +other+ is an Ok wrapping a value equal to this one
      def ==(other)
        return false unless other.is_a?(Result) && other.ok?

        value == other.unwrap!
      end

      # @return [Array(Object)] the wrapped value in a single element array
      def deconstruct
        [value]
      end

      # @param _keys [Array<Symbol>, nil] ignored, every key is always returned
      # @return [Hash{Symbol => Object}] the wrapped value under +:value+
      def deconstruct_keys(_keys)
        { value: }
      end

      # @return [Boolean] always false
      def err?
        false
      end

      # Collapses nested results, returning the innermost one.
      #
      # @return [Result] the innermost result when the value is a Result, otherwise +self+
      def flatten
        return self unless value.is_a?(Result)

        value.flatten
      end

      # Chains another result producing operation onto the wrapped value.
      #
      # @yieldparam value [Object] the wrapped value
      # @yieldreturn [Result] must return a Result
      # @raise [ReturnError] when the block does not return a Result
      # @return [Result] the result returned by the block
      def flat_map
        yield(value).tap { raise ReturnError, "block must return a Result" unless it.is_a?(Result) }
      end

      # Does nothing, since there is no error to chain from.
      #
      # @return [Ok] +self+, without calling the block
      def flat_map_err
        self
      end

      # @return [String] the inspected value wrapped in <tt>Ok<></tt>, such as <tt>Ok<1></tt>
      def inspect
        "Ok<#{value.inspect}>"
      end

      # Transforms the wrapped value.
      #
      # @yieldparam value [Object] the wrapped value
      # @return [Ok] an Ok wrapping the block's return value, which is not flattened when it is itself a Result
      def map
        Result.ok(yield(value))
      end

      # Does nothing, since there is no error to transform.
      #
      # @return [Ok] +self+, without calling the block
      def map_err
        self
      end

      # @return [Boolean] always true
      def ok?
        true
      end

      # Does nothing, since there is no error.
      #
      # @return [Ok] +self+, without calling the block
      def on_err(&)
        self
      end

      # Runs the block with the wrapped value for its side effects.
      #
      # @yieldparam value [Object] the wrapped value
      # @return [Ok] +self+, ignoring the block's return value
      def on_ok
        yield(value)
        self
      end

      # @return [Hash{Symbol => Object}] the +:ok+ variant along with the wrapped value
      def to_h
        { variant: :ok, value: }
      end

      # @return [Object] the wrapped value
      def unwrap!
        value
      end

      # Always raises, since there is no error to unwrap.
      #
      # @raise [ReturnError] always
      def unwrap_err!
        raise ReturnError, "cannot unwrap_err! on Ok"
      end

      # @param _default [Object] ignored
      # @return [Object] the wrapped value
      def unwrap_or(_default)
        value
      end

      # @return [Object] the wrapped value, without calling the block
      def unwrap_or_else(&)
        value
      end

      private

      attr_reader :value
    end
  end
end
