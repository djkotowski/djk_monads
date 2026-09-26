# frozen_string_literal: true

require "open3"

RSpec.describe "require \"djk_monads\"" do # rubocop:disable RSpec/DescribeClass
  # Bundler.require loads a gem by its name, so this must work in a fresh process without anything preloaded.
  it "loads DJK::Monads" do
    lib = File.expand_path("../lib", __dir__)
    output, status = Open3.capture2e(RbConfig.ruby, "-I", lib, "-e", 'require "djk_monads"; print DJK::Monads::Ok')

    expect([output, status.success?]).to eq(["DJK::Monads::Ok", true])
  end
end
