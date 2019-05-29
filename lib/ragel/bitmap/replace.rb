# frozen_string_literal: true

require 'ripper'

module Ragel
  class Bitmap
    class Replace < Ripper::SexpBuilderPP
      class Table
        attr_reader :source, :start_line, :end_line

        def initialize(name, numbers, start_line, end_line)
          @source = source_from(name, numbers)
          @start_line = start_line
          @end_line = end_line
        end

        def source_from(name, numbers)
          width = Math.log2(numbers.max).ceil
          bitmap =
            numbers.each_with_index.inject(0) do |accum, (number, index)|
              accum | (number << (width * index))
            end

          "self.#{name} = ::Ragel::Bitmap.new(#{width}, #{bitmap})"
        end
      end

      attr_reader :tables

      def initialize(*)
        super
        @tables = []
      end

      def self.replace(source)
        replace = Replace.new(source)
        replace.parse

        if replace.error?
          STDERR.puts 'Invalid ruby'
          exit 1
        end

        lines = source.split("\n")
        replace.tables.reverse_each do |table|
          buffer = lines[table.start_line][/\A\s+/]
          source = ["#{buffer}#{table.source}"]
          lines =
            lines[0...table.start_line] + source + lines[table.end_line..-1]
        end

        lines.join("\n") + "\n"
      end

      private

      def on_assign(left, right)
        super.tap do
          next if left[0] != :field || right[0] != :array

          tables <<
            Table.new(
              left[3][1],
              right[1].map { |int| int[1].to_i },
              left[1][1][2][0] - 1,
              right[1].max_by { |int| int[2][0] }[2][0] + 1
            )
        end
      end
    end
  end
end
