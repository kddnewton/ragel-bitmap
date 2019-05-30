# Ragel::Bitmap

[![Build Status](https://travis-ci.com/kddeisz/ragel-bitmap.svg?branch=master)](https://travis-ci.com/kddeisz/ragel-bitmap)

[Ragel](https://www.colm.net/open-source/ragel/) generates ruby code with very large arrays of integers that allocate a lot of memory when required. To reduce memory consumption, this gem replaces those arrays with bitmaps.

## Background

This gem uses bitmaps to reduce memory allocation in place of integer arrays. Say for example we have an array of numbers:

```ruby
[10, 20, 5, 15]
```

We can alternatively represent these numbers as binary, which in ruby looks like:

```ruby
[0b01010, 0b10100, 0b00101, 0b01111]
```

As you can tell from the representation above, at maximum each of these numbers requires 5 bits to represent. So, if we line up all of these bits (starting from the first number), we get:

```ruby
0b01111001011010001010
```

which represents the number `497290` in binary. To get a specific number back out, let's look at the second index (which should be equal to `20` or `0b10100`). In this case we'll shift the bitmap back by the width times the index to make it so that the bits we want are at the bottom of the number:

```ruby
0b01111001011010001010 >> (5 * 1)
# => 0b011110010110100
```

Now that the bits are at the bottom, we can use the `&` operator with the number `0b11111` (which we know of because of the 5 bit width calculated earlier). This will cause all of the `1`s not contained in the first 5 bits to become 0:

```ruby
0b011110010110100 & 0b11111
# => 0b10100
```

We end up with `0b10100`, which is decimal is 20, which is the number we originally put into the array at index 1.

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

After you've run `ragel` to generate your parser, you should then run this gem over the resulting source file and it will replace the integer arrays inline. For example, the following code adds a rake rule to generate the ragel parser from the grammar file and then run `Ragel::Bitmap` over it:

```ruby
rule %r|_parser\.rb\z| => '%X.rl' do |t|
  sh "ragel -s -R -L -F1 -o #{t.name} #{t.source}"
  require 'ragel/bitmap'
  Ragel::Bitmap.replace(t.name)
end
```

Then, in your application, add `require 'ragel/bitmap'` before you require your parser. Now you should be off and running!

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kddeisz/ragel-bitmap.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
