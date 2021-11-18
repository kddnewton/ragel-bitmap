# Ragel::Bitmap

[![Build Status](https://github.com/kddnewton/ragel-bitmap/workflows/Main/badge.svg)](https://github.com/kddnewton/ragel-bitmap/actions)
[![Gem Version](https://img.shields.io/gem/v/ragel-bitmap.svg)](https://rubygems.org/gems/ragel-bitmap)

[Ragel](https://www.colm.net/open-source/ragel/) generates ruby code with very large arrays of integers that allocate a lot of memory when required. To reduce memory consumption, this gem replaces those arrays with packed strings.

For example, let's say you have a very large array of 8-bit unsigned integers (like ragel generates for small parsers). In a lot of places where ragel needs to jump between states, it will interject arrays like:

```ruby
self.transitions =
  [206, 28, 108, 253, 151, 248, 208, 13, 97, 74]
```

For a small array like this, that's not a big deal. But for some very large parsers, that can add up to [a lot of memory overhead](https://github.com/micke/valid_email2/issues/165) even just to parse the file. Using this gem, that line of code would be replaced instead with:

```ruby
self.transitions =
  Ragel::Bitmap::Array8.new("\xCE\x1Cl\xFD\x97\xF8\xD0\raJ")
```

Since the only method that ragel uses on these arrays is `#[]`, that method is implemented as well on `Array8`, which makes it possible to swap this code in seemlessly.

In a lot of cases the numbers contained in these arrays won't quite fit into 8-bit unsigned integers, more often it's 16-bits that you end up needing. For that we use `Ragel::Bitmap::Array16`, as in:

```ruby
self.transitions =
  [22427, 6684, 39361, 52842, 12850, 37505, 53824, 5861, 51699, 63533]
```

becomes:

```ruby
self.transitions =
  Ragel::Bitmap::Array16.new(
    "W\x1A\x99\xCE2\x92\xD2\x16\xC9\xF8",
    "\x9B\x1C\xC1j2\x81@\xE5\xF3-"
    )
```

The two string arguments being given to the `::new` method there signify the high and low byte of each of the numbers, respectively. Then, when we go to pull the numbers back out, we simply get the 8-bit segments from each of the high and low bytes, shift the high byte left by 8 bits, and bitwise-or them together.

This kind of approach works for any size integer, because we can keep splitting it up into multiple bytes. We have explicit support for:

* `Array8` - 1-byte integers
* `Array16` - 2-byte integers
* `Array24` - 3-byte integers
* `Array32` - 4-byte integers
* `Array32Offset` - 4-byte integers using `unpack1` with the offset parameter, available since [3.1.0](https://bugs.ruby-lang.org/issues/18254)
* `Array64Offset` - 8-byte integers using `unpack1` with the offset parameter, available since [3.1.0](https://bugs.ruby-lang.org/issues/18254)
* `ArrayGeneric` - functions with any size integer

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ragel-bitmap'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ragel-bitmap

## Usage

After you've run `ragel` to generate your parser, you should then run this gem over the resulting source file and it will replace the integer arrays with our specialized array substitutions. For example, the following code adds a rake rule to generate the ragel parser from the grammar file and then run `Ragel::Bitmap` over it:

```ruby
rule %r|_parser\.rb\z| => '%X.rl' do |t|
  sh "ragel -s -R -L -F1 -o #{t.name} #{t.source}"
  require 'ragel/bitmap'
  Ragel::Bitmap.replace(t.name)
end
```

Then, in your application, add `require 'ragel/bitmap'` before you require your parser. Now you should be off and running!

We also provide a `ragel-bitmap` command that you can execute once this gem is installed. Usage looks like `ragel-bitmap [path]` where `path` is a path to a generated ragel parser.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kddnewton/ragel-bitmap.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
