# frozen_string_literal: true

require_relative "lib/djk/monads/version"

Gem::Specification.new do |spec|
  spec.name = "djk_monads"
  spec.version = DJK::Monads::VERSION
  spec.authors = ["Dan Kotowski"]
  spec.email = ["dan@dankotowski.dev"]

  spec.summary = "Rust-style monads for Ruby"
  spec.description = "A collection of Rust-like monads for Ruby that I'm using in my personal projects."
  spec.homepage = "https://github.com/djkotowski/djk_monads"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 4.0.0"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/djkotowski/djk_monads/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  excluded = %w[
    bin/
    spec/
    .github/
    Gemfile
    Rakefile
    .gitignore
    .rspec
    .rubocop.yml
    .streerc
    .editorconfig
    .tool-versions
    lefthook.yml
    CLAUDE.md
  ]
  spec.files =
    IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
      ls.readlines("\x0", chomp: true).reject { |f| (f == gemspec) || f.start_with?(*excluded) }
    end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
