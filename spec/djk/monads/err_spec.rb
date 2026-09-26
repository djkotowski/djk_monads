# frozen_string_literal: true

module DJK
  module Monads
    RSpec.describe Err do
      describe "#==" do
        it "is true for an Err wrapping an equal error" do
          error = "boom"

          expect(described_class.new(error)).to eq(described_class.new("boom"))
        end

        it "is false for an Err wrapping a different error" do
          expect(described_class.new("boom")).not_to eq(described_class.new("bang"))
        end

        it "is false for an Ok wrapping an equal value" do
          expect(described_class.new("boom")).not_to eq(Ok.new("boom"))
        end

        it "is false for a value that is not a Result" do
          expect(described_class.new("boom")).not_to eq("boom")
        end
      end

      describe "#deconstruct" do
        it "returns the error in an array" do
          expect(described_class.new("boom").deconstruct).to eq(["boom"])
        end

        it "supports array patterns" do
          described_class.new("boom") => [error]

          expect(error).to eq("boom")
        end
      end

      describe "#deconstruct_keys" do
        it "returns the error keyed by :error" do
          expect(described_class.new("boom").deconstruct_keys(nil)).to eq({ error: "boom" })
        end

        it "supports hash patterns" do
          described_class.new("boom") => { error: }

          expect(error).to eq("boom")
        end
      end

      describe "#err?" do
        it "is true" do
          expect(described_class.new("boom").err?).to be(true)
        end
      end

      describe "#flatten" do
        it "returns self when the error is not a Result" do
          result = described_class.new("boom")

          expect(result.flatten).to be(result)
        end

        it "returns the inner result when the error is an Err" do
          expect(described_class.new(described_class.new("boom")).flatten).to eq(described_class.new("boom"))
        end

        it "returns the inner result when the error is an Ok" do
          expect(described_class.new(Ok.new(1)).flatten).to eq(Ok.new(1))
        end

        it "collapses arbitrarily nested results" do
          expect(described_class.new(described_class.new(described_class.new("boom"))).flatten).to eq(
            described_class.new("boom"),
          )
        end
      end

      describe "#flat_map" do
        it "returns self" do
          result = described_class.new("boom")

          expect(result.flat_map { Result.ok(1) }).to be(result)
        end

        it "does not yield" do
          expect { |block| described_class.new("boom").flat_map(&block) }.not_to yield_control
        end
      end

      describe "#flat_map_err" do
        it "returns the result of the block called with the error" do
          expect(described_class.new("boom").flat_map_err { Result.err("#{it}!") }).to eq(described_class.new("boom!"))
        end

        it "returns an Ok returned by the block" do
          expect(described_class.new("boom").flat_map_err { Result.ok(1) }).to eq(Ok.new(1))
        end

        it "raises when the block does not return a Result" do
          result = described_class.new("boom")

          expect { result.flat_map_err { it } }.to raise_error(ReturnError, "block must return a Result")
        end
      end

      describe "#inspect" do
        it "wraps the inspected error in Err<>" do
          expect(described_class.new("boom").inspect).to eq('Err<"boom">')
        end
      end

      describe "#map" do
        it "returns self" do
          result = described_class.new("boom")

          expect(result.map { 1 }).to be(result)
        end

        it "does not yield" do
          expect { |block| described_class.new("boom").map(&block) }.not_to yield_control
        end
      end

      describe "#map_err" do
        it "wraps the return value of the block in an Err" do
          expect(described_class.new("boom").map_err { "#{it}!" }).to eq(described_class.new("boom!"))
        end

        it "does not flatten a Result returned by the block" do
          expect(described_class.new("boom").map_err { Result.err("bang") }).to eq(
            described_class.new(described_class.new("bang")),
          )
        end
      end

      describe "#ok?" do
        it "is false" do
          expect(described_class.new("boom").ok?).to be(false)
        end
      end

      describe "#on_err" do
        it "returns self" do
          result = described_class.new("boom")

          expect(result.on_err { nil }).to be(result)
        end

        it "yields the error" do
          expect { |block| described_class.new("boom").on_err(&block) }.to yield_with_args("boom")
        end

        it "ignores the return value of the block" do
          expect(described_class.new("boom").on_err { "bang" }).to eq(described_class.new("boom"))
        end
      end

      describe "#on_ok" do
        it "returns self" do
          result = described_class.new("boom")

          expect(result.on_ok { nil }).to be(result)
        end

        it "does not yield" do
          expect { |block| described_class.new("boom").on_ok(&block) }.not_to yield_control
        end
      end

      describe "#to_h" do
        it "returns the variant and the error" do
          expect(described_class.new("boom").to_h).to eq({ variant: :err, error: "boom" })
        end
      end

      describe "#unwrap!" do
        it "raises the wrapped error" do
          expect { described_class.new(ArgumentError.new("boom")).unwrap! }.to raise_error(ArgumentError, "boom")
        end

        it "raises a RuntimeError when the error is a string" do
          expect { described_class.new("boom").unwrap! }.to raise_error(RuntimeError, "boom")
        end
      end

      describe "#unwrap_err!" do
        it "returns the error" do
          expect(described_class.new("boom").unwrap_err!).to eq("boom")
        end
      end

      describe "#unwrap_or" do
        it "returns the default" do
          expect(described_class.new("boom").unwrap_or(1)).to eq(1)
        end
      end

      describe "#unwrap_or_else" do
        it "returns the result of the block called with the error" do
          expect(described_class.new("boom").unwrap_or_else { "#{it}!" }).to eq("boom!")
        end
      end
    end
  end
end
