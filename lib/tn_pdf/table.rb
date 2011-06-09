require 'tn_pdf/table_column'

module TnPDF
  class Table
    attr_accessor *Configuration.table_properties_names

    def initialize(document)
      Configuration.table_properties_names.each do |property|
        send("#{property}=", Configuration["table_#{property}"])
      end
      @document = document
    end

    def columns_hash
      columns_hash = ActiveSupport::OrderedHash.new
      columns.inject(columns_hash) do |hash, column|
        hash[column.header] = column.to_proc
        hash
      end
    end

    def columns_headers
      columns.map(&:header)
    end

    def collection
      @collection ||= Array.new
    end

    def collection=(collection)
      raise ArgumentError unless collection.kind_of? Array
      @collection = collection
    end

    def add_column(column)
      unless column.kind_of? Column
        column = Column.new(column)
      end
      columns << column
    end

    def rows
      collection.map do |object|
        columns.map do |column|
          column.value_for(object)
        end
      end
    end

    def render(max_height)
      x_pos = x_pos_on(document, document_width)
      document.bounding_box([x_pos, document.cursor],
                            :width => document_width,
                            :height => max_height) do

        document.text *([text_before].flatten)

        document.font_size self.font_size

        table_data  = [[header_table]]
        table_data += minitables
        table_data += footer_tables

        document.table(table_data,
                      :column_widths => sane_column_widths) do |table|
          table.header = self.multipage_headers
          stylize_table(table)
        end

        document.text *([text_after].flatten)
      end
    end

    def columns
      @columns ||= []
    end

    def add_footer(row=nil, &block)
      unless block_given? or row.kind_of? Array
        raise ArgumentError, "No block or array was passed"
      end

      row = block.call(collection) if block_given?

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
    private

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

      @prawn_table ||= document.make_table([columns_headers]+rows) do |table|
        columns.each_with_index do |column, index|
          next if column.width.nil? or column.width == 0
          table.column(index).width = column.width
        end

        stylize_table(table)
      end
    end

    def minitables
      row_number = 0 # I hate this as much as you do
      rows.map do |row|
        minitable = document.make_table([row],
                                       :column_widths => sane_column_widths) do |table|
          columns.each_with_index do |column, index|
            table.columns(index).style(column.prawn_style)
          end
          row_number += 1
          stylize_table(table)
          table.cells.background_color = self.row_color(row_number)
        end
        [minitable]
      end
    end

    def header_table
      document.make_table([columns_headers],
                          :column_widths => sane_column_widths) do |table|
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
      column_widths = row.map do |field|
        sane_column_widths[field.colspan_range].inject(:+)
      end

      document.make_table(row_array,
                          :column_widths => column_widths) do |table|

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

    def sane_column_widths
      @sane_column_widths ||= begin
        prawn_widths = prawn_table.column_widths
        extra_space  = document_width - prawn_table.width

        proportions  = prawn_widths.map { |width| width/prawn_table.width }
        proportions.map { |proportion| proportion*(prawn_table.width + extra_space) }
      end
    end

    def document_width
      document.bounds.width
    end
  end

end
