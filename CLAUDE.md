# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`djk_monads` is a Ruby gem providing Rust-style `Result` (`Ok`/`Err`) and `Option` (Some/None) monads under the `DJK::Monads` namespace. It targets **Ruby 4.0+** (`.tool-versions` pins 4.0.6), so code freely uses `it` block params, endless methods, and hash shorthand (`{ value: }`).

## Commands

```bash
bin/setup                                        # bundle install
bundle exec rake                                 # default task: specs + rubocop
bin/rspec                                        # all specs
bin/rspec spec/djk/monads/ok_spec.rb             # one file
bin/rspec spec/djk/monads/ok_spec.rb:42          # one example by line
bin/rubocop -a                                   # lint with safe autocorrect
bin/stree write "lib/**/*.rb" "spec/**/*.rb"     # format with Syntax Tree
bin/stree check "lib/**/*.rb" "spec/**/*.rb"     # check formatting
bin/console                                      # IRB with the gem loaded
```

SimpleCov runs on every spec run (output in `coverage/`). A lefthook pre-commit hook runs `stree write` then `rubocop -a` on staged `.rb`/`.rake` files. CI runs `bin/rspec`, `bin/rubocop` and `bin/stree check` as separate steps.

Syntax Tree owns formatting (print width 120, trailing-comma plugin, no auto-ternary). `.rubocop.yml` inherits `syntax_tree`'s RuboCop config, which disables the `Layout` cops and any style cops that would fight the formatter (e.g. empty methods are expanded onto two lines, trailing commas are left to Syntax Tree). Local RuboCop overrides only add `Metrics` disabled and shorthand hash syntax.

## Architecture

- `lib/djk.rb` → `lib/djk/monads.rb` loads everything via `require_relative`; new files must be added there.
- **Result** (`result.rb`) is an abstract base class: it declares every instance method as an empty `@abstract` stub with YARD docs, and holds the class-level constructors/combinators (`ok`, `err`, `from`, `compact`, `partition`, `traverse`) plus shared `to_hash`/`to_s`. **Ok** and **Err** subclass it and implement every abstract method — each method exists on both, with one side being a no-op that returns `self`. When adding a method, add the abstract stub to `Result` and implement it in both `Ok` and `Err`.
- **Option** (`option.rb`) is a single class, not a subclass pair. It `include`s `Singleton` so `Option.none` is the shared `instance` (value `nil`), while `Option.some` calls the private `new(value:)`. A Some can never wrap `nil`; `Option.from` maps `nil` to None and `map` returns None if the block returns `nil`.
- Both types support pattern matching via `deconstruct`/`deconstruct_keys` (Result: `in Ok[value]`, `in Err[error:]`).
- Block-chaining methods (`flat_map`, `flat_map_err`, `or_else`, `traverse`) validate the block's return type and raise `ReturnError` if it isn't the expected monad. `Option#unwrap!` raises `Option::NoneError`; `Err#unwrap!` raises the wrapped error itself.
- `map` does not flatten nested monads; `flatten` is explicit.

## Conventions

- Every public method has YARD docs (`@param`, `@return`, `@yieldparam`, `@raise`, `@example`); match that style.
- Specs live in `spec/djk/monads/<file>_spec.rb`, wrapped in `module DJK; module Monads` so constants resolve unqualified, using `RSpec.describe` (monkey patching disabled) and `described_class`.
- `sig/` exists for RBS signatures (`bin/rbs`) but is currently empty.
