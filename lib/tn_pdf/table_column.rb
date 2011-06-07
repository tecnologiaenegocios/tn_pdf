module TnPDF
  class Table

    class Column
      attr_reader :header, :proc, :collection, :style, :width

      alias_method :to_proc, :proc
      def initialize(arguments)
        raise ArgumentError unless valid_column_args?(arguments)
        @header = arguments[0].to_s
        @proc   = arguments[1].to_proc
        @style  = Column.style_for(arguments[2])
        @width  = arguments[3].to_i rescue 0
      end

      def values_for(collection)
        collection.map do |object|
          value_for(object)
        end
      end

      def value_for(object)
        value = @proc.call(object)
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

      def prawn_style
        style.reject { |k, v| [:format, :decimal].include? k }
      end

      private

      def valid_column_args?(column_args)
        validity  = true
        validity &= column_args.kind_of? Array
        validity &= [2, 3, 4].include? column_args.count
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
    end

  end
end
