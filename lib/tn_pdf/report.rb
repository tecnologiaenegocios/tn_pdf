module TnPDF
  class Report
    attr_reader :page_header, :page_footer, :table, :record_collection
    attr_accessor *Report.properties_names

    def initialize(properties = {})
      @page_header = PageSection.new
      @page_footer = PageSection.new
      @record_collection = Array.new
      initialize_properties(properties)
    end

    # Yeah, kinda unDRY. But the metaprogramming
    # counterpart's got very unreadable, so I chose
    # to keep the long version.

    def page_header_left=(page_header_left)
      @page_header.left = page_header_left
    end

    def page_footer_left=(page_footer_left)
      @page_footer.left = page_footer_left
    end

    def page_header_right=(page_header_right)
      @page_header.right = page_header_right
    end

    def page_footer_right=(page_footer_right)
      @page_footer.right = page_footer_right
    end

    def page_header_center=(page_header_center)
      @page_header.center = page_header_center
    end

    def page_footer_center=(page_footer_center)
      @page_footer.center = page_footer_center
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

    def render_to(filename)
      table.render_on(document)
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
      Report.properties_names.inject({}) do |properties_hash, property|
        properties_hash[property] = send(property)
        properties_hash
      end
    end

    private

    def initialize_properties(properties)
      Report.properties_names.each do |property|
        properties[property] ||= Report.defaults[property]
        send(:"#{property}=", properties[property])
      end
    end
  end
end
