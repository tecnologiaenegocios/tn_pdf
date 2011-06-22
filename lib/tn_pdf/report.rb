module TnPDF
  # @author Renato Zannon
  # The {TnPDF::Report} class is the easier, best supported and more complete
  # way to access the TnPDF API. It delegates most of it's work to fellow classes
  # such as {TnPDF::Table} and {TnPDF::PageSection}, but the delegation
  # itself and all the necessary setup is made under the hood.
  # This means that everything the code needs to do is access methods such as
  # {#record_collection} and {#table_columns}, and then it is forwarded to the
  # appropriate member.
  #
  # For more specific needs, methods such as {#table} and {#page_header}, which
  # give direct access to the report's members, are provided, so that the user can
  # make low-level/bleeding edge adjustments without being restricted to this
  # classe's interface.
  #
  # @attr [String] page_size
  #   The report's page size, in paper sizes such as "A4" and "Letter".
  #   Supports as much as much paper sizes as Prawn does.
  #
  # @attr [Symbol] page_layout
  #   The resulting pages' layout. Must be :landscape or :portrait
  #
  # @attr [Double] left_margin
  #   Sets the document's left margin. Accepts a Double value, defined in PDF
  #   points (1/72 inch) or a String "in" cm or mm, such as "1.5cm" and
  #   "50mm".
  #
  # @attr [Double] right_margin
  #   Sets the document's right margin. Accepts a Double value, defined in PDF
  #   points (1/72 inch) or a String "in" cm or mm, such as "1.5cm" and
  #   "50mm".
  #
  # @attr [Double] bottom_margin
  #   Sets the document's bottom margin. Accepts a Double value, defined in PDF
  #   points (1/72 inch) or a String "in" cm or mm, such as "1.5cm" and
  #   "50mm".
  #
  # @attr [Double] top_margin
  #   Sets the document's top margin. Accepts a Double value, defined in PDF
  #   points (1/72 inch) or a String "in" cm or mm, such as "1.5cm" and
  #   "50mm".
  #
  # @attr [String] font
  #   The default font to be used on the report. The only (currently) supported
  #   choices are "Helvetica" and "Courier", although Prawn's font embedding
  #   mechanism is a probable upcoming addition
  #
  # @attr [Fixnum] font_size
  #   The default report font size. In the usual "points" unit.
  #
  # @attr [String] images_path
  #   The path from where we will search for the requested images. Defaults to
  #   the current path, "./". In a Rails application, for instance, you would
  #   probably want to set this guy to RAILS_ROOT+"public/images"
  #
  # @attr [String, Array<String, Hash>] text_before_table
  #   Some text to be rendered before the report's table. Can be used as some
  #   kind of prelude/explanation/introduction etc.
  #   It accepts a normal string, that will be rendered using the settings on
  #   {#font} and {#font_size}, or an Array containing a String and a Hash,
  #   the last being an hash of options, as accepted by Prawn's Document#text
  #   method.
  #   @example
  #     report.text_before_table = "Some text"
  #   @example
  #     report.text_before_table = ["Some text", :size => 20]
  #
  # @attr [String, Array<String, Hash>] text_after_table
  #   Some text to be rendered after the report's table. Can be used as a
  #   confirmation, a conclusion, an acceptance term etc.
  #   It accepts a normal string, that will be rendered using the settings on
  #   {#font} and {#font_size}, or an Array containing a String and a Hash,
  #   the last being an hash of options, as accepted by Prawn's Document#text
  #   method.
  #   @example
  #     report.text_after_table = "Some text"
  #   @example
  #     report.text_after_table = ["Some text", :size => 20]
  class Report

    # The underlying {PageSection} that represents the report pages' headers. Direct
    # manipulation is disencouraged.
    # @return [PageSection]
    attr_reader :page_header

    # The underlying {PageSection} that represents the report pages' footers. Direct
    # manipulation is disencouraged.
    # @return [PageSection]
    attr_reader :page_footer

    # The underlying {Table}. Direct manipulation is disencouraged, except in
    # cases where fine adjustments are required, or when some (possibly
    # bleeding-edge) functionality is not implemented on {Report} (yet).
    #
    # An example of this case is {Table#add_footer}, which can't (currently)
    # be accessed by any way except by doing:
    #   report.table.add_footer
    # @return [Table]
    attr_reader :table

    # The underlying {Table}'s collection of objects. Each of these objects
    # will be represented as a table row, by the application of the procedures
    # described using {#table_columns=}. The order in which this property and
    # {#table_columns} are called really an issue, as soon as *both* are set
    # before {#render} is called.
    # @return [Array]
    attr_accessor :record_collection

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
        table.render(table_height)
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
