require 'test_helper'

module Ragel
  class BitmapTest < Minitest::Test
    def test_version
      refute_nil Bitmap::VERSION
    end

    def test_basic_bitmap
      numbers = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
      bitmap = bitmap_from(numbers)

      numbers.each_with_index do |number, index|
        assert_equal number, bitmap[index]
      end
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
