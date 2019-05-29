# frozen_string_literal: true

require 'test_helper'
require 'ragel/bitmap/replace'

module Ragel
  class BitmapTest < Minitest::Test
    def test_version
      refute_nil Bitmap::VERSION
    end

    def test_basic
      numbers = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
      bitmap = bitmap_from(numbers)

      numbers.each_with_index do |number, index|
        assert_equal number, bitmap[index]
      end
    end

    def test_fuzzing
      numbers = Array.new(10) { (rand * 256).floor }
      bitmap = bitmap_from(numbers)

      numbers.each_with_index do |number, index|
        assert_equal number, bitmap[index]
      end
    end

    def test_replace
      expected = <<~RUBY
        module Parser
          self._trans_keys = ::Ragel::Bitmap.new(3, 22737)
        end
      RUBY

      assert_equal expected, Bitmap::Replace.replace(<<~RUBY)
        module Parser
          self._trans_keys = [
            1, 2, 3, 4, 5
          ]
        end
      RUBY
    end

    class NonComputeTable < Bitmap::Replace::Table
      private

      def source_from(*)
        '-- REPLACED --'
      end
    end

    def test_replace_fixture
      fixture = File.join('fixtures', 'address_lists_parser.rb')
      source = File.read(File.expand_path(fixture, __dir__))

      replaced =
        Bitmap::Replace::Table.stub(:new, NonComputeTable.method(:new)) do
          Bitmap::Replace.replace(source)
        end
      assert_equal 7, replaced.scan('-- REPLACED --').size
    end

    private

    def bitmap_from(numbers)
      width = Math.log2(numbers.max).ceil
      bitmap =
        numbers.each_with_index.inject(0) do |accum, (number, index)|
          accum | (number << (width * index))
        end

      Bitmap.new(width, bitmap)
    end
  end
end
