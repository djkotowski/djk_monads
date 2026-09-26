# frozen_string_literal: true

require "singleton"

module DJK
  module Monads
    # An optional value that is either present (Some) or absent (None).
    #
    # Build options with Option.some, Option.none, or Option.from. None is a single shared instance, and a Some can
    # never wrap +nil+.
    #
    # @example
    #   Option.from(1).map { it + 1 }.unwrap_or(0)
    #   # => 2
    #
    #   Option.from(nil).map { it + 1 }.unwrap_or(0)
    #   # => 0
    class Option
      include Singleton

      # Raised by +unwrap!+ when called on None.
      class NoneError < StandardError
      end

      # @api private
      # @param value [Object, nil] the value to wrap, or +nil+ for None
      def initialize(value: nil)
        @value = value
      end

      # @param other [Object] the object to compare against
      # @return [Boolean] true if both are None, or both are a Some wrapping equal values
      def ==(other)
        return false unless other.is_a?(Option)
        return false if some? && other.none?
        return true if none? && other.none?

        value == other.unwrap!
      end

      # Returns the wrapped value, raising +error+ instead of a NoneError when the option is None.
      #
      # @param error [Exception, String] the error to raise for None
      # @raise [Exception] +error+ when the option is None
      # @return [Object] the wrapped value
      def expect(error)
        unwrap!
      rescue NoneError
        raise error
      end

      # Chains another option producing operation onto a Some, passing through None untouched.
      #
      # @yieldparam value [Object] the wrapped value, only for a Some
      # @yieldreturn [Option] must return an Option
      # @raise [ReturnError] when the block does not return an Option
      # @return [Option] the option returned by the block, or +self+ when the receiver is None
      def flat_map
        return self if none?

        yield(value).tap { raise ReturnError, "block must return an Option" unless it.is_a?(Option) }
      end

      # Transforms the value of a Some, passing through None untouched.
      #
      # @yieldparam value [Object] the wrapped value, only for a Some
      # @return [Option] a Some wrapping the block's return value, None when the block returns +nil+, or +self+ when
      #   the receiver is None
      def map
        return self if none?

        Option.from(yield(value))
      end

      # Converts the option into a Result.
      #
      # @param error [Object] the error to wrap when the option is None
      # @return [Ok, Err] an Ok wrapping the value of a Some, or an Err wrapping +error+ for None
      def ok_or(error)
        some? ? Result.ok(value) : Result.err(error)
      end

      # Falls back to another option when the receiver is None.
      #
      # @yieldreturn [Option] must return an Option, only called for None
      # @raise [ReturnError] when the block does not return an Option
      # @return [Option] +self+ for a Some, or the option returned by the block for None
      def or_else
        some? ? self : yield.tap { raise ReturnError, "block must return an Option" unless it.is_a?(Option) }
      end

      # @return [Boolean] true if the option is None
      def none?
        value.nil?
      end

      # @return [Boolean] true if the option is a Some
      def some?
        !none?
      end

      # Returns the wrapped value, raising when the option is None.
      #
      # @raise [NoneError] when the option is None
      # @return [Object] the wrapped value
      def unwrap!
        raise NoneError, "unwrap! called on None" if none?

        value
      end

      # Returns the wrapped value, falling back to +default+ when the option is None.
      #
      # @param default [Object] the value to return for None
      # @return [Object] the wrapped value or +default+
      def unwrap_or(default)
        none? ? default : value
      end

      # Returns the wrapped value, falling back to the block's return value when the option is None.
      #
      # @yieldreturn [Object] the value to return, only called for None
      # @return [Object] the wrapped value or the block's return value
      def unwrap_or_else
        none? ? yield : value
      end

      # @return [Array] the wrapped value in a single element array for a Some, or an empty array for None
      def to_a
        some? ? [value] : []
      end

      # Wraps a value that may be +nil+.
      #
      # @param value [Object, nil] the value to wrap
      # @return [Option] None when +value+ is +nil+, otherwise a Some wrapping +value+
      def self.from(value)
        value.nil? ? none : some(value)
      end

      # @return [Option] the shared None instance
      def self.none = instance

      # Wraps a value that must not be +nil+.
      #
      # @param value [Object] the value to wrap
      # @raise [ArgumentError] when +value+ is +nil+
      # @return [Option] a Some wrapping +value+
      def self.some(value)
        raise ArgumentError, "value cannot be nil" if value.nil?

        new(value:)
      end

      private

      attr_reader :value
    end
  end
end
