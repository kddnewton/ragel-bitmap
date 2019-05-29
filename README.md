# Ragel::Bitmap

[![Build Status](https://travis-ci.com/kddeisz/ragel-bitmap.svg?branch=master)](https://travis-ci.com/kddeisz/ragel-bitmap)

Use bitmaps for ragel-generated code instead of arrays.

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

Use `Ragel::Bitmap.replace(filepath)` where `filepath` is a path to a ragel-generated file. Require `ragel/bitmap` in your code. Profit!

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kddeisz/ragel-bitmap.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
