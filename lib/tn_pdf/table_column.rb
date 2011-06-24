module TnPDF
  class Table
    # Represents a column of a table. Typically not used directly, but through
    # {Table#add_column Table#add_column} and friends.
    class Column
      # Is a String that contains the column header
      # @return [String]
      attr_reader :header

      # Is an object that responds to to_proc, typically a Symbol or a Proc.
      # It represents the procedure used to extract the information from the
      # object.
      # @example
      #   column.proc = :full_name
      # @example
      #   myProc = Proc.new do |person|
      #     "#{person.id} - #{person.name}"
      #   end
      #   column.proc = myProc
      # @return [#to_proc]
      attr_reader :proc

      # Defines how the formatting of the result will occur. Typically used
      # for formatting currencies, numbers etc, but can be anything defined
      # on {Configuration}, the {TnPDF::Configuration.load_from YAML Configuration file}
      # or a Hash that contains (at least) the :format key.
      # It defaults to the :text style.
      # @example
      #   column.style = :currency
      # @example
      #   column.style = { :format  => "%.2f",
      #                    :decimal => ",",
      #                    :align   => :right }
      # @return [Symbol, Hash]
      attr_reader :style

      # Defines the (visual) width of the column. May be defined in PDF
      # points (1/72 inch), a String "in" the cm or mm units, or a String
      # representing a percentage.
      #
      # It is important to note that, in the case of a percentage-based
      # column, it represents a percentage of the *page* on which the table
      # will be rendered, not of the table.
      # @example
      #   width = 1234.45
      # @example
      #   width = "1.5cm"
      # @example
      #   width = "14mm"
      # @example
      #   width = "20%"
      # @return [Double, String]
      attr_accessor :width

      alias_method :to_proc, :proc

      attr_accessor :column_width_type
      # Creates a new Column
      #
      # The parameter has to be an Array in the form:
      #   [header, procedure, style, width]
      # where:
      # [{#header header} (required)]
      #   {include:#header}
      # [{#proc procedure} (required)]
      #   {include:#proc}
      # [{#style style} (optional)]
      #   {include:#style}
      # [{#width width} (optional)]
      #   {include:#width}
      # @example
      #   Column.new [ "Full name", :full_name ]
      # @example
      #   sum = Proc.new { |obj| obj.value_a + obj.value_b }
      #   Column.new [ "Sum", sum, :number, "15%" ]
      def initialize(arguments)
        raise ArgumentError unless valid_column_args?(arguments)
        @header = arguments[0].to_s
        @proc   = arguments[1].to_proc
        @style  = Column.style_for(arguments[2])
        @width  = Configuration.perform_conversions arguments[3]
        if @width.nil?
          column_width_type = :generated
        end
      end

      def value_for(object)
        value = @proc.call(object)
        Column.format_value(value, style)
      end

      def prawn_style
        style.reject { |k, v| [:format, :decimal].include? k }
      end

      def width
        if column_width_type == :percentage
          unless max_width
            raise ArgumentError, "Maximum width should be set for percentage-based widths!"
          end
          match = @width.scan(/(\d+\.?\d*)%/)

          number = match[0][0].to_f/100.0
          number*max_width
        else
          @width
        end
      end

      def column_width_type
        @column_width_type ||=
          if @width.kind_of? String
              (@width =~ /(\d+\.?\d*)%/) ? :percentage : :fixed
          elsif @width.kind_of? Numeric
            :fixed
          else
            :generated
          end
      end

      attr_accessor :index, :max_width
      private

      def valid_column_args?(column_args)
        validity  = true
        validity &= column_args.kind_of? Array
        validity &= (2..4).include? column_args.count
        validity &= column_args[0].respond_to?(:to_s)
        validity &= column_args[1].respond_to?(:to_proc)
      rescue NoMethodError
        valid = false
      ensure
        return validity
      end

      def self.style_for(type)
        if type.nil?
          {:format => "%s"}
        elsif type.kind_of? Symbol
          Configuration["column_#{type}"]
        else
          type
        end
      end

      def self.prawn_style_for(type)
        style_for(type).reject { |k, v| [:format, :decimal].include? k }
      end

      def self.format_value(value, style)
        method = if value.respond_to?(:strftime)
                   value.method(:strftime)
                 elsif value.respond_to?(:sprintf)
                   value.method(:sprintf)
                 else
                   method(:sprintf)
                 end
        string = method.arity == 1 ?
                   method.call(style[:format]) :
                   method.call(style[:format], value)

        string.gsub!(".", style[:decimal]) if style[:decimal]
        return string
      rescue TypeError
        puts "WARNING: Bad format '#{style[:format]}' for value '#{value}'"
        return value.to_s
      end
    end

  end
end
