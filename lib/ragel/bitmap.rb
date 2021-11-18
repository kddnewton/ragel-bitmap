# frozen_string_literal: true

require 'ragel/bitmap/version'

# Polyfilling `getbyte` in order to support ruby 1.8
unless ''.respond_to?(:getbyte)
  class String
    def getbyte(index)
      self[index].ord
    end
  end
end

module Ragel
  module Bitmap
    class Array8
      def initialize(string)
        @string = string
      end

      def [](idx)
        @string.getbyte(idx)
      end
    end

    class Array16
      def initialize(highstring, lowstring)
        @highstring = highstring
        @lowstring = lowstring
      end

      def [](idx)
        (@highstring.getbyte(idx) << 8) | @lowstring.getbyte(idx)
      end
    end

    class Array24
      def initialize(highstring, middlestring, lowstring)
        @highstring = highstring
        @middlestring = middlestring
        @lowstring = lowstring
      end

      def [](idx)
        (@highstring.getbyte(idx) << 16) |
          (@middlestring.getbyte(idx) << 8) |
          @lowstring.getbyte(idx)
      end
    end

    class Array32
      def initialize(first, second, third, fourth)
        @first = first
        @second = second
        @third = third
        @fourth = fourth
      end

      def [](idx)
        (@first.getbyte(idx) << 24) |
          (@second.getbyte(idx) << 16) |
          (@third.getbyte(idx) << 8) |
          @fourth.getbyte(idx)
      end
    end

    class Array32Offset
      def initialize(string)
        @string = string
      end

      def [](idx)
        @string.unpack1('L', offset: idx * 4)
      end
    end

    class Array64Offset
      def initialize(string)
        @string = string
      end

      def [](idx)
        @string.unpack1('Q', offset: idx * 8)
      end
    end

    class ArrayGeneric
      def initialize(*strings)
        @strings = strings
      end

      def [](idx)
        shift = @strings.length * 8
        @strings.inject(0) do |product, bitmap|
          shift -= 8
          product | (bitmap.getbyte(idx) << shift)
        end
      end
    end

    def self.replace(filepath)
      require 'ragel/bitmap/replace'

      File.write(filepath, Replace.replace(File.read(filepath)))
    end
  end
end
