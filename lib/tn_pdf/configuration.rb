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
        else
          report_defaults[property]
        end
      end

      def header_properties_names
        header_defaults.keys.map { |k| "page_header_#{k}".to_sym }
      end

      def footer_properties_names
        footer_defaults.keys.map { |k| "page_footer_#{k}".to_sym }
      end

      def properties_names
        report_defaults.keys +
          header_properties_names +
          footer_properties_names
      end

      private

      def report_defaults
        {
          :page_size => "A4",
          :page_orientation => :landscape,
          :left_margin => 1.cm,
          :right_margin => 1.cm,
          :top_margin => 0.cm,
          :bottom_margin => 0.cm
        }
      end

      def header_defaults
        {
          :height =>  4.cm,
          :left   =>  { :text => "Teste" },
          :center =>  { :text => "de" },
          :right  =>  { :text => "cabeçalho" }
        }
      end


      def footer_defaults
        {
          :height =>  1.cm,
          :left   =>  { :text => "Teste" },
          :center =>  { :text => "de" },
          :right  =>  { :text => "rodapé" }
        }
      end
    end
  end
end
