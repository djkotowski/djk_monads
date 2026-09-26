# frozen_string_literal: true

module DJK
  module Monads
    RSpec.describe Option do
      describe "#==" do
        it "is true for a Some wrapping an equal value" do
          value = 1

          expect(described_class.some(value)).to eq(described_class.some(1))
        end

        it "is false for a Some wrapping a different value" do
          expect(described_class.some(1)).not_to eq(described_class.some(2))
        end

        it "is true for None compared with None" do
          none = described_class.none

          expect(none).to eq(described_class.none)
        end

        it "is false for a Some compared with None" do
          expect(described_class.some(1)).not_to eq(described_class.none)
        end

        it "is false for None compared with a Some" do
          expect(described_class.none).not_to eq(described_class.some(1))
        end

        it "is false for a value that is not an Option" do
          expect(described_class.some(1)).not_to eq(1)
        end
      end

      describe "#expect" do
        it "returns the value of a Some" do
          expect(described_class.some(1).expect(ArgumentError.new("boom"))).to eq(1)
        end

        it "raises the given error for None" do
          expect { described_class.none.expect(ArgumentError.new("boom")) }.to raise_error(ArgumentError, "boom")
        end
      end

      describe "#flat_map" do
        it "returns the result of the block called with the value" do
          expect(described_class.some(1).flat_map { described_class.some(it + 1) }).to eq(described_class.some(2))
        end

        it "returns None when the block returns None" do
          expect(described_class.some(1).flat_map { described_class.none }).to eq(described_class.none)
        end

        it "raises when the block does not return an Option" do
          expect { described_class.some(1).flat_map { it } }.to raise_error(ReturnError, "block must return an Option")
        end

        it "returns self for None" do
          expect(described_class.none.flat_map { described_class.some(1) }).to eq(described_class.none)
        end

        it "does not yield for None" do
          expect { |block| described_class.none.flat_map(&block) }.not_to yield_control
        end
      end

      describe "#map" do
        it "wraps the return value of the block in a Some" do
          expect(described_class.some(1).map { it + 1 }).to eq(described_class.some(2))
        end

        it "returns None when the block returns nil" do
          expect(described_class.some(1).map { nil }).to eq(described_class.none)
        end

        it "returns self for None" do
          expect(described_class.none.map { 1 }).to eq(described_class.none)
        end

        it "does not yield for None" do
          expect { |block| described_class.none.map(&block) }.not_to yield_control
        end
      end

      describe "#ok_or" do
        it "returns an Ok wrapping the value of a Some" do
          expect(described_class.some(1).ok_or("boom")).to eq(Result.ok(1))
        end

        it "returns an Err wrapping the given error for None" do
          expect(described_class.none.ok_or("boom")).to eq(Result.err("boom"))
        end
      end

      describe "#or_else" do
        it "returns self for a Some" do
          option = described_class.some(1)

          expect(option.or_else { described_class.some(2) }).to be(option)
        end

        it "does not yield for a Some" do
          expect { |block| described_class.some(1).or_else(&block) }.not_to yield_control
        end

        it "returns the result of the block for None" do
          expect(described_class.none.or_else { described_class.some(1) }).to eq(described_class.some(1))
        end

        it "raises when the block does not return an Option" do
          expect { described_class.none.or_else { 1 } }.to raise_error(ReturnError, "block must return an Option")
        end
      end

      describe "#none?" do
        it "is true for None" do
          expect(described_class.none.none?).to be(true)
        end

        it "is false for a Some" do
          expect(described_class.some(1).none?).to be(false)
        end
      end

      describe "#some?" do
        it "is true for a Some" do
          expect(described_class.some(1).some?).to be(true)
        end

        it "is false for None" do
          expect(described_class.none.some?).to be(false)
        end
      end

      describe "#unwrap!" do
        it "returns the value of a Some" do
          expect(described_class.some(1).unwrap!).to eq(1)
        end

        it "raises for None" do
          expect { described_class.none.unwrap! }.to raise_error(Option::NoneError, "unwrap! called on None")
        end
      end

      describe "#unwrap_or" do
        it "returns the value of a Some instead of the default" do
          expect(described_class.some(1).unwrap_or(2)).to eq(1)
        end

        it "returns the default for None" do
          expect(described_class.none.unwrap_or(2)).to eq(2)
        end
      end

      describe "#unwrap_or_else" do
        it "returns the value of a Some" do
          expect(described_class.some(1).unwrap_or_else { 2 }).to eq(1)
        end

        it "does not yield for a Some" do
          expect { |block| described_class.some(1).unwrap_or_else(&block) }.not_to yield_control
        end

        it "returns the result of the block for None" do
          expect(described_class.none.unwrap_or_else { 2 }).to eq(2)
        end
      end

      describe "#to_a" do
        it "returns the value of a Some in an array" do
          expect(described_class.some(1).to_a).to eq([1])
        end

        it "returns an empty array for None" do
          expect(described_class.none.to_a).to eq([])
        end
      end

      describe ".from" do
        it "wraps a value in a Some" do
          expect(described_class.from(1)).to eq(described_class.some(1))
        end

        it "returns None for nil" do
          expect(described_class.from(nil)).to be(described_class.none)
        end

        it "wraps false in a Some" do
          expect(described_class.from(false)).to eq(described_class.some(false))
        end
      end

      describe ".none" do
        it "is none" do
          expect(described_class.none.none?).to be(true)
        end

        it "returns the same instance every time" do
          none = described_class.none

          expect(none).to be(described_class.none)
        end
      end

      describe ".some" do
        it "wraps the value" do
          expect(described_class.some(1).unwrap!).to eq(1)
        end

        it "raises for nil" do
          expect { described_class.some(nil) }.to raise_error(ArgumentError, "value cannot be nil")
        end
      end
    end
  end
end
