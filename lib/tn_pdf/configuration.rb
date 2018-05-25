require 'yaml'
module TnPDF

  class Configuration
    class << self

      attr_accessor :image_loader

      def [](property, call_procs: true)
        (hash, key) = filter_property(property)
        value = hash[key]

        if call_procs && value.kind_of?(Proc)
          value.call
        else
          value
        end
      end

      def []=(property, value)
        (hash, key) = filter_property(property)
        value = perform_conversions(value)

        hash[key] = value
      end

      def report_properties_names
        report.keys
      end

      def header_properties_names
        header.keys
      end

      def footer_properties_names
        footer.keys
      end

      def table_properties_names
        table.keys
      end

      def properties_names
        report_properties_names.map { |p| "report_#{p}" }  +
          header_properties_names.map { |p| "page_header_#{p}" } +
          footer_properties_names.map { |p| "page_footer_#{p}" } +
          table_properties_names.map { |p| "table_#{p}" }
      end

      def load_from(yaml_file)
        configurations = YAML.load_file(yaml_file)

        configurations.each do |item, value|
          value = perform_conversions(value)
          self.send(item).merge! value
        end
      end

      def perform_conversions(value)
        match = value.match(/^(\d+\.?\d*)(cm|mm)$/) rescue nil
        if match
          num = match[1].to_f
          conversion = match[2].to_sym
          num.send(conversion)
        elsif value.kind_of? Hash
          value.inject({}) do |hash, (k, v)|
            hash[k.to_sym] = perform_conversions(v)
            hash
          end
        elsif value.kind_of? Array
          value.inject([]) do |array, v|
            array << perform_conversions(v)
            array
          end
        else
          value
        end
      end

      private

      def report
        @report ||= {
          :page_size => "A4",
          :page_layout => :landscape,
          :left_margin => 1.cm,
          :right_margin => 1.cm,
          :top_margin => 0.cm,
          :bottom_margin => 0.cm,
          :font => "Courier",
          :font_size => 10,
          :images_path => "./",
          :text_before_table => "",
          :text_after_table => "",
        }
      end

      def header
        @header ||= {
          :height =>  1.cm,
          :top => 0.5.cm,
          :bottom => 0.2.cm,
          :left => {},
          :right => {},
          :center => {}
        }
      end


      def footer
        @footer ||= {
          :height =>  1.cm,
          :top => 0.2.cm,
          :bottom => 0.1.cm,
          :left => {},
          :right => {},
          :center => {}
        }
      end

      def table
        @table ||= {
          :align => :center,
          :text_before => "",
          :text_after  => "",
          :multipage_headers => true,
          :font_size => 10,
          :header_font_style => :bold,
          :header_font_size => 10,
          :header_font => 'Courier',
          :header_color => "FF0000",
          :footer_font_style => :bold,
          :footer_font_size => 10,
          :footer_font => 'Courier',
          :footer_color => "FF0000",
          :odd_row_color => "00FF00",
          :even_row_color => "0000FF",
          :borders => false,
        }
      end

      def column
        @column ||= {
          :currency => { :format => "%0.2f",
                         :align => :right,
                         :decimal => "," },

          :number   => { :format => "%d",
                         :align => :right},

          :date => { :format => "%d/%m/%Y",
                     :align  => :center },

          :float => { :format => "%0.3f",
                           :align => :right,
                           :decimal => "," },

          :text => { :format => "%s",
                     :align => :left },

          :right_text => { :format => "%s",
                     :align => :right },
        }
      end

      def filter_property(property)
        property = property.to_s
        case property
          when /^page_header_/
            property_key = property.sub('page_header_','').to_sym
            [header,property_key]
          when /^page_footer_/
            property_key = property.sub('page_footer_','').to_sym
            [footer,property_key]
          when /^table_/
            property_key = property.sub('table_','').to_sym
            [table,property_key]
          when /^column_/
            property_key = property.sub('column_','').to_sym
            [column,property_key]
          else
            [report,property.to_sym]
        end
      end

    end
  end
end
