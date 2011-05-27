module TnPDF

  class Configuration
    class << self


      def [](property)
        property = property.to_s
        case property
          when /^page_header_/
            property_key = property.sub('page_header_','').to_sym
            header_defaults[property_key]
          when /^page_footer_/
            property_key = property.sub('page_footer_','').to_sym
            footer_defaults[property_key]
          when /^table_/
            property_key = property.sub('table_','').to_sym
            table_defaults[property_key]
          else
            report_defaults[property.to_sym]
        end
      end

      def report_properties_names
        report_defaults.keys
      end

      def header_properties_names
        header_defaults.keys
      end

      def footer_properties_names
        footer_defaults.keys
      end

      def table_properties_names
        table_defaults.keys
      end

      def properties_names
        report_properties_names.map { |p| "report_#{p}" }  +
          header_properties_names.map { |p| "page_header_#{p}" } +
          footer_properties_names.map { |p| "page_footer_#{p}" } +
          table_properties_names.map { |p| "table_#{p}" }
      end

      private

      def report_defaults
        {
          :page_size => "A4",
          :page_layout => :landscape,
          :left_margin => 1.cm,
          :right_margin => 1.cm,
          :top_margin => 0.cm,
          :bottom_margin => 0.cm,
        }
      end

      def header_defaults
        {
          :height =>  1.cm,
          :top => 0.5.cm,
          :bottom => 0.2.cm,
          :left   =>  { :text => "Teste" },
          :center =>  { :text => "de" },
          :right  =>  { :text => "cabeçalho" }
        }
      end


      def footer_defaults
        {
          :height =>  1.cm,
          :top => 0.2.cm,
          :bottom => 0.1.cm,
          :left   =>  { :text => "Teste" },
          :center =>  { :text => "de" },
          :right  =>  { :text => "rodapé" }
        }
      end

      def table_defaults
        {
          :align   => :center,
          :multipage_headers => :true,
        }
      end
    end
  end
end
