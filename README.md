# DjkMonads

Rust-style `Result` and `Option` monads for Ruby.

- **`Result`**: the outcome of an operation that either succeeds with a value (`Ok`) or fails with an error (`Err`).
- **`Option`**: a value that is either present (Some) or absent (None).

Both support chaining (`map`, `flat_map`), unwrapping with fallbacks, and pattern matching.

## Requirements

Ruby 4.0 or newer.

## Installation

The gem hasn't been published to RubyGems yet. Install it from GitHub by adding it to your Gemfile:

```ruby
gem "djk_monads", github: "djkotowski/djk_monads"
```

Then require it:

```ruby
require "djk"

include DJK::Monads # optional, lets you write Result and Option unqualified
```

To use the types without the namespace everywhere, define them as top-level constants instead:

```ruby
DJK::Monads.apply_aliases!
# => [:ReturnError, :Err, :Ok, :Option, :Result]
```

This defines `ReturnError`, `Err`, `Ok`, `Option` and `Result` at the top level. Any of those names that's already defined is left alone and left out of the returned list, and a warning naming it is printed to stderr.

## Usage

### Result

Build results with `Result.ok`, `Result.err` or `Result.from`. Don't instantiate `Ok` or `Err` directly.

```ruby
Result.ok(1).map { it + 1 }
# => Ok<2>

Result.err("boom").unwrap_or(0)
# => 0

# Result.from runs the block and wraps any StandardError it raises in an Err
Result.from { Integer("oops") }.map_err(&:message)
# => Err<"invalid value for Integer(): \"oops\"">
```

Chain operations that can fail with `flat_map`. The block must return a `Result`, or a `DJK::Monads::ReturnError` is raised:

```ruby
Result.ok(2).flat_map { |n| n.even? ? Result.ok(n / 2) : Result.err("odd") }
# => Ok<1>
```

Pattern match on the variant:

```ruby
case Result.from { Integer("42") }
in Ok[value] then value
in Err[error] then error.message
end
# => 42
```

Hash patterns work too, with `in Ok[value:]` and `in Err[error:]`.

#### Instance methods

| Method | `Ok` | `Err` |
| --- | --- | --- |
| `ok?` / `err?` | `true` / `false` | `false` / `true` |
| `map { }` | wraps the block's return value in `Ok` | returns `self` |
| `map_err { }` | returns `self` | wraps the block's return value in `Err` |
| `flat_map { }` | returns the block's `Result` | returns `self` |
| `flat_map_err { }` | returns `self` | returns the block's `Result` |
| `on_ok { }` / `on_err { }` | runs the block for side effects, returns `self` | same |
| `flatten` | returns the innermost nested `Result` | same |
| `unwrap!` | returns the value | raises the wrapped error |
| `unwrap_err!` | raises `ReturnError` | returns the error |
| `unwrap_or(default)` | returns the value | returns `default` |
| `unwrap_or_else { \|error\| }` | returns the value | returns the block's return value |
| `to_h` | `{ variant: :ok, value: }` | `{ variant: :err, error: }` |

`map` does not flatten: if its block returns a `Result`, you get a nested result. Use `flat_map`, or call `flatten`.

`Err#unwrap!` raises the wrapped error as is, so it works best when the error is an exception or a message string.

#### Working with collections

```ruby
# Split results into their values and their errors
Result.partition([Result.ok(1), Result.err("boom"), Result.ok(2)])
# => [[1, 2], ["boom"]]

# Map each element to a Result and collect the values, stopping at the first Err
Result.traverse(%w[1 2 3]) { |s| Result.from { Integer(s) } }
# => Ok<[1, 2, 3]>

Result.traverse(%w[1 x 3]) { |s| Result.from { Integer(s) } }.map_err(&:message)
# => Err<"invalid value for Integer(): \"x\"">

# Remove every Ok wrapping nil
Result.compact([Result.ok(nil), Result.ok(1), Result.err(nil)])
# => [Ok<1>, Err<nil>]
```

### Option

Build options with `Option.some`, `Option.none` or `Option.from`. None is a single shared instance, and a Some can never wrap `nil`. `Option.some(nil)` raises `ArgumentError`.

```ruby
Option.from(nil).map { it + 1 }.unwrap_or(0)
# => 0

Option.from({ a: 1 }[:a]).map { it * 10 }.unwrap!
# => 10

Option.none.or_else { Option.some(5) }.unwrap!
# => 5

# Convert to a Result
Option.from(nil).ok_or("missing")
# => Err<"missing">

# Raise your own error instead of Option::NoneError
Option.none.expect(KeyError.new("no key"))
# raises KeyError: no key
```

`Option#map` returns None when the block returns `nil`. `flat_map` and `or_else` blocks must return an `Option`, or a `DJK::Monads::ReturnError` is raised.

Other methods: `some?`, `none?`, `unwrap_or_else { }` and `to_a` (`[value]` for a Some, `[]` for None).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then run `bundle exec rake` to run the specs and RuboCop, which is what CI runs. `bin/console` opens an interactive prompt with the gem loaded.

Formatting uses [Syntax Tree](https://github.com/ruby-syntax-tree/syntax_tree) (`bin/stree write`) and [RuboCop](https://rubocop.org) (`bin/rubocop -a`). A [lefthook](https://github.com/evilmartians/lefthook) pre-commit hook runs both on staged files. Run `bundle exec lefthook install` to enable it.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `lib/djk/monads/version.rb`, then run `bundle exec rake release`. That creates a git tag for the version, pushes the commits and the tag, and pushes the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/djkotowski/djk_monads. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/djkotowski/djk_monads/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
