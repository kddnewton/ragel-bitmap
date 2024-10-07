# frozen_string_literal: true

require "prism"

module Ragel
  module Bitmap
    # A ruby parser that finds instances of table declarations in a
    # ragel-outputted file.
    module Replace
      class << self
        # Get the required args for a bitmap from a set of numbers
        def bitmap_args_from(numbers)
          size = (Math.log2(numbers.max) / 8).ceil

          case size
          when 1
            [:Array8, [numbers.pack("C*")]]
          when 2
            [:Array16, strings_from(2, numbers)]
          when 3
            [:Array24, strings_from(3, numbers)]
          when 4
            if offset?
              [:Array32Offset, [numbers.pack("L*")]]
            else
              [:Array32, strings_from(4, numbers)]
            end
          when 8
            if offset?
              [:Array64Offset, [numbers.pack("Q*")]]
            else
              [:ArrayGeneric, strings_from(size, numbers)]
            end
          else
            [:ArrayGeneric, strings_from(size, numbers)]
          end
        end

        # Check if we can use the offset keyword argument for the unpack1 method
        # introduced here: https://bugs.ruby-lang.org/issues/18254. If we can,
        # then it'll be more efficient than storing multiple strings and
        # shifting.
        def offset?
          String
            .instance_method(:unpack1)
            .parameters
            .any? { |(type, name)| type == :key && name == :offset }
        end

        private

        # This will take a set of numbers and return a set of strings that
        # represent their bytes in the same order. For example, if you passed in
        # the numbers [10, 100, 1000] and said to encode them into 2 strings,
        # you would receive back the strings:
        #
        #     "\x00\x00\x03"
        #     "\x0a\x64\xe8"
        #
        # Read vertically, (with the first one being the higher byte) you'll
        # see they add up to the input numbers. See the work below:
        #
        #     0x000a = 0d0010
        #     0x0064 = 0d0100
        #     0x03e8 = 0d1000
        #
        # To get the original numbers back, we can do much the same as we just
        # did in that example, which is to read the strings in highest to lowest
        # byte order, getting the bytes out at the same index every time. Then
        # for each high string, shifting it left the requisite number of bytes
        # (in the example above it's 8 since it's just 2 strings, if it were 3
        # strings then the first string would be shifted by 16, and so on).
        def strings_from(size, numbers)
          size
            .downto(1)
            .map do |index|
              shift = (index - 1) * 8
              numbers.map { |number| (number >> shift) & 0xff }.pack("C*")
            end
        end
      end

      # Represents a table declaration in the source
      class Table
        attr_reader :source, :start_line, :end_line

        def initialize(node)
          @source =
            source_from(
              node.name.name.chomp("="),
              node.arguments.arguments.first.elements.map(&:value)
            )

          @start_line = node.location.start_line
          @end_line = node.location.end_line
        end

        private

        def source_from(name, numbers)
          clazz, strings = Replace.bitmap_args_from(numbers)
          arguments = strings.map(&:inspect).join(", ")
          "self.#{name} = ::Ragel::Bitmap::#{clazz}.new(#{arguments})"
        end
      end

      # Represents the source as it changes
      class Buffer
        attr_reader :lines

        def initialize(source)
          @lines = source.split("\n")
        end

        def replace(table)
          buffer = lines[table.start_line - 1][/\A\s+/]
          source = ["#{buffer}#{table.source}"]

          @lines =
            lines[0...(table.start_line - 1)] + source +
              lines[table.end_line..-1]
        end

        def to_source
          "#{lines.join("\n")}\n"
        end
      end

      class Visitor < Prism::Visitor
        attr_reader :tables

        def initialize(tables)
          super
          @tables = tables
        end

        def visit_call_node(node)
          if node.name.match?(/^_.+=$/) &&
               (arguments = node.arguments&.arguments)&.size == 1 &&
               arguments.first.is_a?(Prism::ArrayNode)
            tables << Table.new(node)
          end

          super
        end
      end

      def self.replace(source)
        result = Prism.parse(source)

        if result.failure?
          warn "Invalid ruby"
          exit 1
        end

        tables = []
        result.value.accept(Visitor.new(tables))

        buffer = Buffer.new(source)
        tables.reverse_each { |table| buffer.replace(table) }

        buffer.to_source
      end
    end
  end
end
