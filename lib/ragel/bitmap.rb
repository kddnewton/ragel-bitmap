# frozen_string_literal: true

require 'ragel/bitmap/version'

module Ragel
  # An integer bitmap that contains a width (the number of bytes that the
  # largest integer requires) and a bitmap (an integer that is the combination
  # of the element integers)
  class Bitmap
    def initialize(size, directive, bitmap)
      @size = size
      @directive = directive
      @bitmap = bitmap
    end

    def [](index)
      @bitmap.byteslice(index * @size, @size).unpack(@directive).first
    end

    def self.replace(filepath)
      require 'ragel/bitmap/replace'

      File.write(filepath, Replace.replace(File.read(filepath)))
    end
  end
end
