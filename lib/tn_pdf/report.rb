module TnPDF
  class Report
    attr_reader :page_header, :page_footer, :table, :record_collection
    attr_accessor *Configuration.properties_names

    def initialize(properties = {})
      @page_header = PageSection.new
      @page_footer = PageSection.new
      @record_collection = Array.new
      initialize_properties(properties)
    end

    class << self
      private

      def forward_property(property)
        property = property.to_s

        # Regexp match example: page_footer_height
        # the regex catches page_footer as "object",
        # and height as "the method_name".
        property.scan(/^(.*)_([^_]*)$/) do |object, method_name|
          class_eval <<-STRING
            def #{property}
              #{object}.#{method_name}
            end

            def #{property}=(value)
              #{object}.#{method_name} = value
            end
          STRING
        end
      end

    end

    properties_to_forward = Configuration.header_properties_names +
                              Configuration.footer_properties_names

    properties_to_forward.each do |property|
      forward_property(property)
    end

    def record_collection=(collection)
      unless collection.kind_of? Array
        raise ArgumentError, "collection should be an Array!"
      end
      @record_collection = table.collection = collection
    end

    def table_columns
      table.columns || Array.new
    end

    def table_columns=(columns)
      raise ArgumentError unless columns.kind_of? Array
      columns.each do |column|
        table.add_column column
      end
    end

    def render(filename)
      document_width = document.bounds.width
      page_header_position = [0, document.cursor]
      page_footer_position = [0, Configuration[:page_footer_height]]

      document.repeat :all do
        page_header.render(document, page_header_position)
        document.stroke_horizontal_rule
      end

      document.bounding_box([2.cm, 20.cm], :width => 20.cm, :height => 10.cm) do
        table.render(document)
      end

      document.repeat :all do
        page_footer.render(document, page_footer_position)
      end

      document.render_file filename
    end

    def document
      @document ||= Prawn::Document.new(properties)
    end

    def table
      @table ||= Table.new
    end

    # Configurable properties

    def properties
      @properties ||=
        Configuration.properties_names.inject({}) do |properties_hash, property|
          properties_hash[property] = send(property)
          properties_hash
        end
    end

    private

    def initialize_properties(properties)
      Configuration.properties_names.each do |property|
        properties[property] ||= Configuration[property]
        send(:"#{property}=", properties[property])
      end
    end


  end
end
