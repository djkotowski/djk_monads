# frozen_string_literal: true

RSpec.describe DJK::Monads do
  it "has a version number" do
    expect(DJK::Monads::VERSION).not_to be_nil
  end

  describe ".apply_aliases!" do
    let(:names) { %i[ReturnError Err Ok Option Result] }

    around do |example|
      defined_before = names.select { Object.const_defined?(it, false) }
      example.run
    ensure
      # stub_const can't undo constants created by the code under test, so remove them directly.
      (names - defined_before).each { Object.send(:remove_const, it) if Object.const_defined?(it, false) } # rubocop:disable RSpec/RemoveConst
    end

    it "defines each constant at the top level" do
      described_class.apply_aliases!

      expect(names.map { Object.const_get(it, false) }).to eq(names.map { described_class.const_get(it) })
    end

    it "returns the names of the constants it defined" do
      expect(described_class.apply_aliases!).to eq(names)
    end

    it "does not overwrite a constant that is already defined" do
      stub_const("Ok", :existing)

      described_class.apply_aliases!

      expect(Object.const_get(:Ok, false)).to eq(:existing)
    end

    it "does not return the names of constants that were already defined" do
      stub_const("Ok", :existing)

      expect(described_class.apply_aliases!).to eq(names - [:Ok])
    end

    it "defines nothing when called a second time" do
      described_class.apply_aliases!

      expect(described_class.apply_aliases!).to be_empty
    end

    it "warns on stderr about constants that are already defined" do
      stub_const("Ok", :existing)
      stub_const("Result", :existing)

      message = /apply_aliases! skipped already defined constants: Ok, Result$/

      expect { described_class.apply_aliases! }.to output(message).to_stderr
    end

    it "does not warn when no constants are already defined" do
      expect { described_class.apply_aliases! }.not_to output.to_stderr
    end

    it "does not warn about constants it defined on an earlier call" do
      described_class.apply_aliases!

      expect { described_class.apply_aliases! }.not_to output.to_stderr
    end
  end
end
