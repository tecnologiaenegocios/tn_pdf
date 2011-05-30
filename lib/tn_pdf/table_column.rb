module TnPDF
  class Table

    class Column
      attr_reader :header, :proc, :collection, :style

      alias_method :to_proc, :proc
      def initialize(arguments)
        raise ArgumentError unless valid_column_args?(arguments)
        @header = arguments[0].to_s
        @proc   = arguments[1].to_proc
        @style = style_for(arguments[2])
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

      private

      def valid_column_args?(column_args)
        validity  = true
        validity &= column_args.kind_of? Array
        validity &= column_args.count == 2 || column_args.count == 3
        validity &= column_args[0].respond_to?(:to_s)
        validity &= column_args[1].respond_to?(:to_proc)
      rescue NoMethodError
        valid = false
      ensure
        return validity
      end

      def style_for(type)
        if type.nil?
          {:format => "%s"}
        elsif type.kind_of? Symbol
          Configuration["column_#{type}"]
        else
          type
        end
      end
    end

  end
end
