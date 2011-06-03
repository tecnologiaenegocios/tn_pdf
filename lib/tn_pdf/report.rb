module TnPDF
  class Report
    attr_reader :page_header, :page_footer, :table, :record_collection
    attr_accessor *Configuration.report_properties_names

    def initialize(properties = {})
      @page_header = PageSection.new
      @page_footer = PageSection.new
      @record_collection = Array.new
      initialize_properties(properties)
    end

    class << self
      private

      def forward_property(object_name, property)
        class_eval <<-STRING
          def #{object_name}_#{property}
          #{object_name}.#{property}
          end

          def #{object_name}_#{property}=(value)
          #{object_name}.#{property} = value
          end
        STRING
      end

    end

    Configuration.header_properties_names.each do |property|
      forward_property("page_header", property)
    end

    Configuration.footer_properties_names.each do |property|
      forward_property("page_footer", property)
    end

    Configuration.table_properties_names.each do |property|
      forward_property("table", property)
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

      document.font(font)
      document.font_size(font_size)

      document.repeat :all do
        page_header.render(document, page_header_position)
        document.stroke_horizontal_rule
      end

      table_height = page_body_height

      document.bounding_box([0, document.cursor],
                            :width  => document.bounds.width) do
        document.text text_before_table
        table.render(table_height)
        document.text text_after_table
      end

      document.repeat :all do
        page_footer.render(document, page_footer_position)
      end

      document.render_file filename
    end

    def page_body_height
      height  = document.bounds.height
      height -= page_header.total_height
      height -= page_footer.total_height
    end

    def document
      @document ||= Prawn::Document.new(properties)
    end

    def table
      @table ||= Table.new(document)
    end

    # Configurable properties

    def properties
      Configuration.report_properties_names.inject({}) do |properties_hash, property|
        properties_hash[property] = send(property)
        properties_hash
      end
    end

    private

    def initialize_properties(properties)
      owned_properties  = Configuration.report_properties_names
      owned_properties += Configuration.footer_properties_names.map do |p|
        "page_footer_#{p}"
      end
      owned_properties += Configuration.header_properties_names.map do |p|
        "page_header_#{p}"
      end
      owned_properties += Configuration.table_properties_names.map do |p|
        "table_#{p}"
      end

      owned_properties.each do |property|
        properties[property] ||= Configuration[property]
        send(:"#{property}=", properties[property])
      end

    end

  end
end
