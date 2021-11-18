# frozen_string_literal: true

require 'test_helper'
require 'ragel/bitmap/replace'

module Ragel
  class BitmapTest < Minitest::Test
    def test_version
      refute_nil Bitmap::VERSION
    end

    def test_array8
      assert_bitmap :Array8, [0, 1, 2]
    end

    def test_array16
      assert_bitmap :Array16, [2**16 - 3, 2**16 - 2, 2**16 - 1]
    end

    def test_array24
      assert_bitmap :Array24, [2**24 - 3, 2**24 - 2, 2**24 - 1]
    end

    def test_array32
      type = Bitmap::Replace.offset? ? :Array32Offset : :Array32
      assert_bitmap type, [2**32 - 3, 2**32 - 2, 2**32 - 1]
    end

    def test_array64
      type = Bitmap::Replace.offset? ? :Array64Offset : :Array64
      assert_bitmap type, [2**64 - 3, 2**64 - 2, 2**64 - 1]
    end

    def test_fuzzing
      assert_bitmap :Array8, Array.new(100) { (rand * 256).floor }
    end

    def test_replace
      expected = <<~RUBY
        module Parser
          self._trans_keys = ::Ragel::Bitmap::Array8.new("\\x01\\x02\\x03\\x04\\x05")
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

    def assert_bitmap(type, numbers)
      bitmap = bitmap_from(numbers)
      assert_equal type, bitmap.class.name.split('::').last.to_sym

      numbers.each_with_index do |number, index|
        assert_equal number, bitmap[index]
      end
    end

    def bitmap_from(numbers)
      clazz, strings = Bitmap::Replace.bitmap_args_from(numbers)
      Bitmap.const_get(clazz).new(*strings)
    end
  end
end
