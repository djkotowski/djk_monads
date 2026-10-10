# frozen_string_literal: true

require "open3"
require "djk/monads/expectations"

module DJK
  module Monads
    RSpec.describe "djk/monads/expectations" do
      # Runs a script in a fresh Ruby process, so load order isn't affected by what this suite has already required.
      def run_ruby(script)
        lib = File.expand_path("../../../lib", __dir__)
        output, status = Open3.capture2e(RbConfig.ruby, "-I", lib, "-e", script)
        [output, status.success?]
      end

      def failure_message(actual, matcher)
        expect(actual).to matcher
        nil
      rescue RSpec::Expectations::ExpectationNotMetError => e
        e.message
      end

      def negated_failure_message(actual, matcher)
        expect(actual).not_to matcher
        nil
      rescue RSpec::Expectations::ExpectationNotMetError => e
        e.message
      end

      describe "loading" do
        let(:matchers_defined_script) do
          'print RSpec::Matchers.method_defined?(:be_ok_result) ? "loaded" : "not loaded"'
        end

        it "is not loaded by require \"djk_monads\" when rspec-expectations is present" do
          script = "require 'rspec/expectations'; require 'djk_monads'; #{matchers_defined_script}"

          expect(run_ruby(script)).to eq(["not loaded", true])
        end

        it "does not load rspec-expectations through require \"djk_monads\"" do
          expect(run_ruby('require "djk_monads"; print defined?(RSpec).inspect')).to eq(["nil", true])
        end

        it "loads the matchers and DJK::Monads through require \"djk/monads/expectations\"" do
          script = "require 'djk/monads/expectations'; print DJK::Monads::Ok, ' '; #{matchers_defined_script}"

          expect(run_ruby(script)).to eq(["DJK::Monads::Ok loaded", true])
        end
      end

      describe "be_ok_result" do
        let(:not_a_result) { 1 }

        it "passes for an Ok" do
          expect(Ok.new(1)).to be_ok_result
        end

        it "passes for an Ok wrapping nil" do
          expect(Ok.new(nil)).to be_ok_result
        end

        it "fails for an Err" do
          expect(failure_message(Err.new("boom"), be_ok_result)).to eq('expected Err<"boom"> to be an Ok result')
        end

        it "fails for a value that is not a Result" do
          expect(failure_message(not_a_result, be_ok_result)).to eq("expected 1 to be an Ok result")
        end

        it "passes when negated for an Err" do
          expect(Err.new("boom")).not_to be_ok_result
        end

        it "fails when negated for an Ok" do
          expect(negated_failure_message(Ok.new(1), be_ok_result)).to eq("expected Ok<1> not to be an Ok result")
        end
      end

      describe "be_err_result" do
        context "without an error class" do
          let(:not_a_result) { "boom" }

          it "passes for an Err" do
            expect(Err.new("boom")).to be_err_result
          end

          it "fails for an Ok" do
            expect(failure_message(Ok.new(1), be_err_result)).to eq("expected Ok<1> to be an Err result")
          end

          it "fails for a value that is not a Result" do
            expect(failure_message(not_a_result, be_err_result)).to eq('expected "boom" to be an Err result')
          end

          it "passes when negated for an Ok" do
            expect(Ok.new(1)).not_to be_err_result
          end

          it "fails when negated for an Err" do
            expect(negated_failure_message(Err.new("boom"), be_err_result)).to eq(
              'expected Err<"boom"> not to be an Err result',
            )
          end
        end

        context "with an error class" do
          it "passes for an Err wrapping an instance of the class" do
            expect(Err.new(KeyError.new("k"))).to be_err_result(KeyError)
          end

          it "passes for an Err wrapping an instance of a subclass" do
            expect(Err.new(KeyError.new("k"))).to be_err_result(StandardError)
          end

          it "passes for an Err wrapping a non-exception error" do
            expect(Err.new(:not_found)).to be_err_result(Symbol)
          end

          it "fails for an Err wrapping a different class, naming the actual error class" do
            expect(failure_message(Err.new("boom"), be_err_result(KeyError))).to eq(
              'expected Err<"boom"> to be an Err result of type KeyError, but got String',
            )
          end

          it "fails for an Ok" do
            expect(failure_message(Ok.new(1), be_err_result(KeyError))).to eq(
              "expected Ok<1> to be an Err result of type KeyError",
            )
          end

          it "passes when negated for an Err wrapping a different class" do
            expect(Err.new("boom")).not_to be_err_result(KeyError)
          end

          it "passes when negated for an Ok" do
            expect(Ok.new(1)).not_to be_err_result(KeyError)
          end

          it "fails when negated for an Err wrapping an instance of the class" do
            expect(negated_failure_message(Err.new(:not_found), be_err_result(Symbol))).to eq(
              "expected Err<:not_found> not to be an Err result of type Symbol",
            )
          end
        end
      end
    end
  end
end
