# frozen_string_literal: true

module DJK
  module Monads
    RSpec.describe Result do
      describe "#to_hash" do
        it "returns the hash representation of an Ok" do
          expect(described_class.ok(1).to_hash).to eq({ variant: :ok, value: 1 })
        end

        it "returns the hash representation of an Err" do
          expect(described_class.err("boom").to_hash).to eq({ variant: :err, error: "boom" })
        end

        it "allows a result to be splatted into a hash" do
          expect({ **described_class.ok(1) }).to eq({ variant: :ok, value: 1 })
        end
      end

      describe "#to_s" do
        it "returns the inspected Ok" do
          expect(described_class.ok(1).to_s).to eq("Ok<1>")
        end

        it "returns the inspected Err" do
          expect(described_class.err("boom").to_s).to eq('Err<"boom">')
        end
      end

      describe ".compact" do
        it "removes Ok results wrapping nil" do
          expect(described_class.compact([described_class.ok(nil), described_class.ok(1)])).to eq(
            [described_class.ok(1)],
          )
        end

        it "keeps Ok results wrapping false" do
          expect(described_class.compact([described_class.ok(false)])).to eq([described_class.ok(false)])
        end

        it "keeps Err results wrapping nil" do
          expect(described_class.compact([described_class.err(nil)])).to eq([described_class.err(nil)])
        end

        it "preserves the order of the remaining results" do
          results = [described_class.ok(1), described_class.ok(nil), described_class.err("boom"), described_class.ok(2)]

          expect(described_class.compact(results)).to eq(
            [described_class.ok(1), described_class.err("boom"), described_class.ok(2)],
          )
        end

        it "returns an empty array when given no results" do
          expect(described_class.compact([])).to eq([])
        end
      end

      describe ".err" do
        it "wraps the error in an Err" do
          expect(described_class.err("boom")).to eq(Err.new("boom"))
        end

        it "wraps a nil error" do
          expect(described_class.err(nil).unwrap_err!).to be_nil
        end
      end

      describe ".from" do
        it "wraps the return value of the block in an Ok" do
          expect(described_class.from { 1 }).to eq(described_class.ok(1))
        end

        it "wraps a raised StandardError in an Err" do
          error = described_class.from { raise ArgumentError, "boom" }.unwrap_err!

          expect(error).to be_a(ArgumentError).and have_attributes(message: "boom")
        end

        it "does not rescue exceptions that are not StandardError" do
          expect { described_class.from { raise NotImplementedError, "boom" } }.to raise_error(NotImplementedError)
        end
      end

      describe ".ok" do
        it "wraps the value in an Ok" do
          expect(described_class.ok(1)).to eq(Ok.new(1))
        end

        it "wraps a nil value" do
          expect(described_class.ok(nil).unwrap!).to be_nil
        end
      end

      describe ".partition" do
        let(:results) do
          [described_class.ok(1), described_class.err("boom"), described_class.ok(2), described_class.err("bang")]
        end

        it "splits unwrapped values from unwrapped errors" do
          expect(described_class.partition(results)).to eq([[1, 2], %w[boom bang]])
        end

        it "returns two empty groups when given no results" do
          expect(described_class.partition([])).to eq([[], []])
        end

        it "raises when any element is not a Result" do
          results = [described_class.ok(1), 2]

          expect { described_class.partition(results) }.to raise_error(ArgumentError, "results must all be Result")
        end
      end

      describe ".traverse" do
        it "collects the unwrapped values into an Ok" do
          result = described_class.traverse([1, 2, 3]) { described_class.ok(it * 2) }

          expect(result).to eq(described_class.ok([2, 4, 6]))
        end

        it "returns an Ok of an empty array when given no values" do
          expect(described_class.traverse([]) { described_class.ok(it) }).to eq(described_class.ok([]))
        end

        it "returns the first Err" do
          result = described_class.traverse([1, 2, 3]) { it.odd? ? described_class.err(it) : described_class.ok(it) }

          expect(result).to eq(described_class.err(1))
        end

        it "stops yielding once a block returns an Err" do
          yielded = []
          results = { 1 => described_class.ok(1), 2 => described_class.err("boom"), 3 => described_class.ok(3) }

          described_class.traverse([1, 2, 3]) { |value| results.fetch(value).tap { yielded << value } }

          expect(yielded).to eq([1, 2])
        end

        it "raises when the block does not return a Result" do
          expect { described_class.traverse([1]) { it } }.to raise_error(ReturnError, "block must return a Result")
        end
      end
    end
  end
end
