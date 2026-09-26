# frozen_string_literal: true

module DJK
  module Monads
    # The outcome of an operation that can either succeed with a value (Ok) or fail with an error (Err).
    #
    # Build results with Result.ok, Result.err, or Result.from rather than instantiating the subclasses directly.
    #
    # @abstract Subclassed by Ok and Err, which implement every instance method.
    # @example
    #   Result.ok(1).map { it + 1 }
    #   # => Ok<2>
    #
    #   case Result.from { Integer("oops") }
    #   in Ok[value] then value
    #   in Err[error] then error.message
    #   end
    #   # => "invalid value for Integer(): \"oops\""
    class Result
      # Compares this result with another object.
      #
      # @abstract
      # @param other [Object] the object to compare against
      # @return [Boolean] true if +other+ is a Result of the same variant wrapping an equal value
      def ==(other); end

      # Destructures the result for array patterns, exposing the wrapped value or error.
      #
      # @abstract
      # @return [Array] a single element array holding the value (Ok) or the error (Err)
      def deconstruct; end

      # Destructures the result for hash patterns.
      #
      # @abstract
      # @param keys [Array<Symbol>, nil] the keys requested by the pattern
      # @return [Hash] the wrapped value or error keyed by variant
      def deconstruct_keys(keys); end

      # @abstract
      # @return [Boolean] true if the result is an Err
      def err?; end

      # Collapses a result wrapping another result into a single result.
      #
      # @abstract
      # @return [Result] the innermost result, or +self+ when nothing is nested
      def flatten; end

      # Chains another result producing operation onto an Ok, passing through an Err untouched.
      #
      # @abstract
      # @yieldparam value [Object] the wrapped value, only for an Ok
      # @yieldreturn [Result] must return a Result
      # @return [Result] the result returned by the block, or +self+ when the receiver is an Err
      def flat_map; end

      # Chains another result producing operation onto an Err, passing through an Ok untouched.
      #
      # @abstract
      # @yieldparam error [Object] the wrapped error, only for an Err
      # @yieldreturn [Result] must return a Result
      # @return [Result] the result returned by the block, or +self+ when the receiver is an Ok
      def flat_map_err; end

      # @abstract
      # @return [String] a human readable representation of the result
      def inspect; end

      # Transforms the value of an Ok, passing through an Err untouched.
      #
      # @abstract
      # @yieldparam value [Object] the wrapped value, only for an Ok
      # @return [Result] an Ok wrapping the block's return value, or +self+ when the receiver is an Err
      def map; end

      # Transforms the error of an Err, passing through an Ok untouched.
      #
      # @abstract
      # @yieldparam error [Object] the wrapped error, only for an Err
      # @return [Result] an Err wrapping the block's return value, or +self+ when the receiver is an Ok
      def map_err; end

      # @abstract
      # @return [Boolean] true if the result is an Ok
      def ok?; end

      # Runs the block for its side effects when the result is an Err.
      #
      # @abstract
      # @yieldparam error [Object] the wrapped error, only for an Err
      # @return [Result] +self+
      def on_err; end

      # Runs the block for its side effects when the result is an Ok.
      #
      # @abstract
      # @yieldparam value [Object] the wrapped value, only for an Ok
      # @return [Result] +self+
      def on_ok; end

      # @abstract
      # @return [Hash] the result's variant along with its value or error
      def to_h; end

      # Returns the wrapped value, raising when the result is an Err.
      #
      # @abstract
      # @raise [Object] the wrapped error when the result is an Err
      # @return [Object] the wrapped value
      def unwrap!; end

      # Returns the wrapped error, raising when the result is an Ok.
      #
      # @abstract
      # @raise [ReturnError] when the result is an Ok
      # @return [Object] the wrapped error
      def unwrap_err!; end

      # Returns the wrapped value, falling back to +default+ when the result is an Err.
      #
      # @abstract
      # @param default [Object] the value to return for an Err
      # @return [Object] the wrapped value or +default+
      def unwrap_or(default); end

      # Returns the wrapped value, falling back to the block's return value when the result is an Err.
      #
      # @abstract
      # @yieldparam error [Object] the wrapped error, only for an Err
      # @return [Object] the wrapped value or the block's return value
      def unwrap_or_else; end

      # Implicit hash conversion, which lets a result be splatted into a hash with <tt>**result</tt>.
      #
      # @return [Hash] the same hash as +to_h+
      def to_hash = to_h

      # @return [String] the same string as +inspect+
      def to_s = inspect

      # Removes all instances of <tt>Ok<nil></tt> from +results+, preserving the order of the remaining results.
      #
      # @param results [Array<Result>] the results to compact
      # @return [Array<Result>] +results+ without any Ok wrapping +nil+
      def self.compact(results)
        results.reject { it.ok? && it.unwrap!.nil? }
      end

      # Creates a new Err.
      #
      # @param error [Object] the error to wrap
      # @return [Err] an Err wrapping +error+
      def self.err(error)
        Err.new(error)
      end

      # Runs the provided block, wrapping the returned value in Ok. If an exception is raised, returns an Err with
      # that exception instead.
      #
      # Only StandardError and its subclasses are rescued, so exceptions such as NotImplementedError still propagate.
      #
      # @yieldreturn [Object] the value to wrap in an Ok
      # @return [Ok, Err] an Ok wrapping the block's return value, or an Err wrapping the exception it raised
      def self.from
        Result.ok(yield)
      rescue StandardError => e
        Result.err(e)
      end

      # Creates a new Ok.
      #
      # @param value [Object] the value to wrap
      # @return [Ok] an Ok wrapping +value+
      def self.ok(value)
        Ok.new(value)
      end

      # Splits results into their unwrapped values and unwrapped errors, preserving their order.
      #
      # @param results [Array<Result>] the results to split
      # @raise [ArgumentError] when any element of +results+ is not a Result
      # @return [Array(Array, Array)] the unwrapped values of every Ok, followed by the unwrapped errors of every Err
      # @example
      #   Result.partition([Result.ok(1), Result.err("boom"), Result.ok(2)])
      #   # => [[1, 2], ["boom"]]
      def self.partition(results)
        raise ArgumentError, "results must all be Result" unless results.all?(Result)

        results.each_with_object([[], []]) do |result, (ok, err)|
          result.on_ok { |value| ok << value }.on_err { |error| err << error }
        end
      end

      # Maps each value in +values+ through a block, collecting the unwrapped values into an <tt>Ok<Array></tt>.
      # Short-circuits on the first Err.
      #
      # @param values [Enumerable] the values to map to results
      # @yieldparam value [Object] each element of +values+
      # @yieldreturn [Result] must return a Result
      # @return [Ok<Array>, Err] all unwrapped values if all block calls returned Ok or the first Err encountered
      # @example
      #   Result.traverse([1, 2, 3]) { |n| Result.ok(n * 2) }
      #   # => Ok<[2, 4, 6]>
      #
      #   Result.traverse([1, 2, 3]) { |n| n == 2 ? Result.err("bad") : Result.ok(n) }
      #   # => Err<"bad">
      def self.traverse(values)
        values.reduce(Result.ok([])) do |result, value|
          result.flat_map do |outputs|
            yield(value)
              .tap { raise ReturnError, "block must return a Result" unless it.is_a?(Result) }
              .map { |output| [*outputs, output] }
          end
        end
      end
    end
  end
end
