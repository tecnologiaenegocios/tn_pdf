require 'tn_pdf/table_column'

module TnPDF
  # A representation {Report}'s table. It's an abstraction above a Prawn
  # table that that 'defaultizes' a commonly used structure - a table that is a
  # {#collection} of elements displayed as {#rows}, on which each of the {#columns}
  # is a property of an object.
  #
  # Through {Table::Column}, it also provides many configurable
  # column 'types', such as currency and float, to ease the pain of formatting
  # the table on a consistent manner.
  #
  # Above that, it also provides a very useful feature that Prawn misses:
  # column spanning (although currently only on footers).
  #
  # == Table footers
  #
  # Table footers are special rows that are often used to make a summary of
  # the table data.
  #
  # The main differences between a footer row and a ordinary row are:
  # [Column spanning]
  #   Normal row's cells can't span across multiple columns,
  #   while a footer cell can.
  # [Calculation]
  #   In a normal row, the cells' values are automatically
  #   calculated using the provided method, while in a footer
  #   row the displayed value should be directly passed.
  # [Scope]
  #   A footer row acts in the scope of the whole collection, while
  #   a normal row represents a single object.
  # [Format]
  #   Footer rows can be formatted in a differente manner, through
  #   the use of the +table_footer_*+ properties on {Configuration}
  class Table
    attr_accessor *Configuration.table_properties_names

    def initialize(document)
      Configuration.table_properties_names.each do |property|
        send("#{property}=", Configuration["table_#{property}"])
      end
      @document = document
    end

    # The collection of objects to be represented by the table.
    # @return [Array]
    # @raise [ArgumentError] If the passed value isn't an Array
    attr_accessor :collection
    def collection
      @collection ||= Array.new
    end

    def collection=(collection)
      raise ArgumentError unless collection.kind_of? Array
      @collection = collection
    end

    # The columns already set on this table. Despite of being first provided
    # as Arrays, the members of this collection are instances of {Column}.
    # @return [Array]
    attr_reader :columns
    def columns(type = :all)
      @columns ||= []
      if type == :all
        @columns
      else
        @columns.select { |c| c.column_width_type == type }
      end
    end

    # Adds a column to the table. The argument should be a {Column}, or an
    # argument that {Column#initialize} accepts.
    # @param [Column] (see Column#initialize)
    def add_column(column)
      unless column.kind_of? Column
        column = Column.new(column)
      end
      column.index = columns.count
      column.max_width = document_width
      columns << column
    end

    def remove_column(column)
      if column.kind_of? Column
        columns.delete(column)
      elsif column.kind_of? Fixnum
        columns.delete_at(column)
      else
        raise ArgumentError, "Unrecognized argument '#{column.inspect}'"
      end
    end

    def reset_columns
      @columns = []
    end

    # The already computed rows of the table. Needs {#columns} and
    # {#collection} to be already set to return something meaningful.
    # @return [Array] An array containing the rows to be rendered.
    def rows
      collection.map do |object|
        columns.map do |column|
          column.value_for(object)
        end
      end
    end

    def render(max_height)
      x_pos = x_pos_on(document, document_width)

      initialize_generated_widths
      total_width = self.column_widths.sum

      document.bounding_box([x_pos, document.cursor],
                            :width => total_width,
                            :height => max_height) do

        table_data  = [[header_table]]
        table_data += minitables
        table_data += footer_tables

        document.text *([text_before].flatten)
        document.font_size self.font_size

        document.table(table_data, :column_widths => [total_width],
                                   :width => total_width) do |table|

          table.header = self.multipage_headers
          stylize_table(table)
        end

        document.text *([text_after].flatten)
      end
    end

    # Adds a footer row to the table.
    #
    # The argument to this method should be an Array (or a block that returns
    # an Array) in which each member is a cell in the format:
    #   [content, colspan, style]
    # where:
    # [*content*]
    #   Is the content of the cell. May be a label, a sum of some values
    #   from the collection etc.
    # [*colspan*]
    #   A number representing how many columns of the table this cell is going
    #   to span across. Be warned that the sum of all the colspans on a given
    #   footer row should always match the number of columns in the table, or
    #   an exception will be raised.
    # [*style*]
    #   The formatting style of the cell. Refer to {Column#style Column#style}
    #   for details.
    # @example
    #   # On a table that has 2 columns
    #   table.add_footer [
    #     ["Total", 1, :text],
    #     [12345,   1, :number]
    #   ]
    # @example
    #   # On a table that has 3 columns
    #   table.add_footer do |collection|
    #     calculation = collection.map(&:value).sum
    #     [
    #       ["Calculation", 1, :text],
    #       [calculation,   2, :number]
    #     ]
    #   end
    def add_footer(row=nil, &block)
      unless block_given? or row.kind_of? Array
        raise ArgumentError, "No block or array was passed"
      end

      row = block.call(collection) if block_given?

      # [content, colspan, style]
      row = row.map do |field|
        field[2] ||= :text
        content = Column.format_value(field[0],
                                      Column.style_for(field[2]))

        OpenStruct.new(:content => content,
                       :colspan => field[1],
                       :style   => Column.prawn_style_for(field[2]) )
      end

      row.inject(0) do |first_column, field|
        final_column = first_column+field.colspan-1
        field.colspan_range = (first_column..final_column)
        final_column+1
      end

      total_colspan = row.map(&:colspan).inject(:+)
      unless total_colspan == columns.length
        raise ArgumentError,
          "Total colspan value '#{total_colspan}' differs from the "+
          "table's columns number '#{columns.length}'"
      end

      footer_rows << row
    end

    def row_color(row_number)
      row_number % 2 == 0 ?
        self.even_row_color:
        self.odd_row_color
    end

    def column_widths(type = :all)
      selected_columns = columns(type)
      selected_columns.sort_by(&:index).map(&:width)
    end

    private

    def columns_headers
      columns.map(&:header)
    end

    def x_pos_on(document, table_width)
      case align
      when :left
        0
      when :center
        (document.bounds.right - table_width)/2.0
      when :right
        document.bounds.right - table_width
      else
        0
      end
    end

    def document
      @document
    end

    def prawn_table
      if @prev_headers != columns_headers or
         @prev_rows != rows

        @prawn_table = nil
        @prev_headers = columns_headers
        @prev_rows    = rows
      end

      @prawn_table ||= begin
        document.make_table([columns_headers]+rows) do |table|
          stylize_table(table)
        end
      end
    end

    def minitables
      row_number = 0 # I hate this as much as you do
      rows.map do |row|
        minitable = document.make_table([row],
                                       :column_widths => column_widths) do |table|
          columns.each_with_index do |column, index|
            table.columns(index).style(column.prawn_style)
          end
          document.font_size = self.font_size
          row_number += 1
          stylize_table(table)
          table.cells.background_color = self.row_color(row_number)
        end
        [minitable]
      end
    end

    def header_table
      document.make_table([columns_headers],
                          :column_widths => column_widths) do |table|
        header_row = table.row(0)
        header_row.background_color = self.header_color
        header_row.font_style = self.header_font_style
        header_row.size = self.header_font_size
        header_row.font = self.header_font
        header_row.align = :center

        stylize_table(table)
      end
    end

    def stylize_table(table)
      table.cells.borders = borders || []
    end

    def footer_rows
      @footer_rows ||= []
    end

    def footer_tables
      footer_rows.map do |row|
        [footer_table_for(row)]
      end
    end

    def footer_table_for(row)
      row_array     = [row.map(&:content)]
      footer_column_widths = row.map do |field|
        column_widths[field.colspan_range].inject(:+)
      end

      document.make_table(row_array,
                          :column_widths => footer_column_widths) do |table|

        footer_row = table.row(0)
        footer_row.background_color = self.footer_color
        footer_row.font_style = self.footer_font_style
        footer_row.size = self.footer_font_size
        footer_row.font = self.footer_font

        row.each_with_index do |field, index|
          table.columns(index).style(field.style)
        end
        stylize_table(table)
      end
    end

    def initialize_generated_widths
      columns(:generated).each do |column|
        index = column.index
        column.width = prawn_table.columns(index).width
      end
      generated_widths_sum = column_widths(:generated).sum

      fixed_widths_sum = column_widths(:fixed).sum
      percentage_widths_sum = column_widths(:percentage).sum
      remaining_space = document_width - percentage_widths_sum - fixed_widths_sum

      columns(:generated).each do |column|
        width = column.width
        column.width = (width/generated_widths_sum)*remaining_space
        column.column_width_type = :fixed
      end
    end

    def document_width
      document.bounds.width
    end
  end

end
