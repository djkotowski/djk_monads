# frozen_string_literal: true

module DJK
  module Monads
    RSpec.describe Ok do
      describe "#==" do
        it "is true for an Ok wrapping an equal value" do
          value = 1

          expect(described_class.new(value)).to eq(described_class.new(1))
        end

        it "is false for an Ok wrapping a different value" do
          expect(described_class.new(1)).not_to eq(described_class.new(2))
        end

        it "is false for an Err wrapping an equal error" do
          expect(described_class.new(1)).not_to eq(Err.new(1))
        end

        it "is false for a value that is not a Result" do
          expect(described_class.new(1)).not_to eq(1)
        end
      end

      describe "#deconstruct" do
        it "returns the value in an array" do
          expect(described_class.new(1).deconstruct).to eq([1])
        end

        it "supports array patterns" do
          described_class.new(1) => [value]

          expect(value).to eq(1)
        end
      end

      describe "#deconstruct_keys" do
        it "returns the value keyed by :value" do
          expect(described_class.new(1).deconstruct_keys(nil)).to eq({ value: 1 })
        end

        it "supports hash patterns" do
          described_class.new(1) => { value: }

          expect(value).to eq(1)
        end
      end

      describe "#err?" do
        it "is false" do
          expect(described_class.new(1).err?).to be(false)
        end
      end

      describe "#flatten" do
        it "returns self when the value is not a Result" do
          result = described_class.new(1)

          expect(result.flatten).to be(result)
        end

        it "returns the inner result when the value is an Ok" do
          expect(described_class.new(described_class.new(1)).flatten).to eq(described_class.new(1))
        end

        it "returns the inner result when the value is an Err" do
          expect(described_class.new(Err.new("boom")).flatten).to eq(Err.new("boom"))
        end

        it "collapses arbitrarily nested results" do
          expect(described_class.new(described_class.new(described_class.new(1))).flatten).to eq(described_class.new(1))
        end
      end

      describe "#flat_map" do
        it "returns the result of the block called with the value" do
          expect(described_class.new(1).flat_map { Result.ok(it + 1) }).to eq(described_class.new(2))
        end

        it "returns an Err returned by the block" do
          expect(described_class.new(1).flat_map { Result.err("boom") }).to eq(Err.new("boom"))
        end

        it "raises when the block does not return a Result" do
          expect { described_class.new(1).flat_map { it } }.to raise_error(ReturnError, "block must return a Result")
        end
      end

      describe "#flat_map_err" do
        it "returns self" do
          result = described_class.new(1)

          expect(result.flat_map_err { Result.ok(2) }).to be(result)
        end

        it "does not yield" do
          expect { |block| described_class.new(1).flat_map_err(&block) }.not_to yield_control
        end
      end

      describe "#inspect" do
        it "wraps the inspected value in Ok<>" do
          expect(described_class.new("a").inspect).to eq('Ok<"a">')
        end
      end

      describe "#map" do
        it "wraps the return value of the block in an Ok" do
          expect(described_class.new(1).map { it + 1 }).to eq(described_class.new(2))
        end

        it "does not flatten a Result returned by the block" do
          expect(described_class.new(1).map { Result.ok(2) }).to eq(described_class.new(described_class.new(2)))
        end
      end

      describe "#map_err" do
        it "returns self" do
          result = described_class.new(1)

          expect(result.map_err { "boom" }).to be(result)
        end

        it "does not yield" do
          expect { |block| described_class.new(1).map_err(&block) }.not_to yield_control
        end
      end

      describe "#ok?" do
        it "is true" do
          expect(described_class.new(1).ok?).to be(true)
        end
      end

      describe "#on_err" do
        it "returns self" do
          result = described_class.new(1)

          expect(result.on_err { nil }).to be(result)
        end

        it "does not yield" do
          expect { |block| described_class.new(1).on_err(&block) }.not_to yield_control
        end
      end

      describe "#on_ok" do
        it "returns self" do
          result = described_class.new(1)

          expect(result.on_ok { nil }).to be(result)
        end

        it "yields the value" do
          expect { |block| described_class.new(1).on_ok(&block) }.to yield_with_args(1)
        end

        it "ignores the return value of the block" do
          expect(described_class.new(1).on_ok { 2 }).to eq(described_class.new(1))
        end
      end

      describe "#to_h" do
        it "returns the variant and the value" do
          expect(described_class.new(1).to_h).to eq({ variant: :ok, value: 1 })
        end
      end

      describe "#unwrap!" do
        it "returns the value" do
          expect(described_class.new(1).unwrap!).to eq(1)
        end
      end

      describe "#unwrap_err!" do
        it "raises" do
          expect { described_class.new(1).unwrap_err! }.to raise_error(ReturnError, "cannot unwrap_err! on Ok")
        end
      end

      describe "#unwrap_or" do
        it "returns the value instead of the default" do
          expect(described_class.new(1).unwrap_or(2)).to eq(1)
        end
      end

      describe "#unwrap_or_else" do
        it "returns the value" do
          expect(described_class.new(1).unwrap_or_else { 2 }).to eq(1)
        end

        it "does not yield" do
          expect { |block| described_class.new(1).unwrap_or_else(&block) }.not_to yield_control
        end
      end
    end
  end
end
