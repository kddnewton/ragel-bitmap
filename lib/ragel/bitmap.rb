# frozen_string_literal: true

require 'ragel/bitmap/version'

module Ragel
  class Bitmap
    attr_reader :width, :bitmap

    def initialize(width, bitmap)
      @width = width
      @bitmap = bitmap
    end

    def [](index)
      (bitmap >> (width * index)) & (2**width - 1)
    end

    def self.replace(filepath)
      require 'ragel/bitmap/replace'

      File.write(filepath, Replace.replace(File.read(filepath)))
    end
  end
end
