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
      x_pos = x_pos_on(document, prawn_table.width)
      document.bounding_box([x_pos, document.cursor],
                            :width => prawn_table.width,
                            :height => max_height) do
        document.font_size self.font_size
        document.table([[header_table], *minitables]+[footer_tables]) do |table|
          stylize_table(table)
        end
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
        OpenStruct.new(:content => field[0],
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
      @prawn_table ||= document.make_table([columns_headers]+rows,
                          :width => document.bounds.width.round) do |table|
        stylize_table(table)
      end
    end

    def minitables
      rows.map do |row|
        minitable = document.make_table([row], :width => prawn_table.width) do |table|
          table.column_widths = prawn_table.column_widths
          columns.each_with_index do |column, index|
            table.columns(index).style(column.prawn_style)
          end
          stylize_table(table)
        end
        [minitable]
      end
    end

    def header_table
      document.make_table([columns_headers], :width => prawn_table.width) do |table|
        table.column_widths = prawn_table.column_widths
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
      table.header = self.multipage_headers
      table.cells.borders = borders || []
      table.row_colors = [self.odd_row_color, self.even_row_color]
    end

    def footer_rows
      @footer_rows ||= []
    end

    def footer_tables
      footer_rows.map do |row|
        footer_table_for(row)
      end
    end

    def footer_table_for(row)
      row_array = [row.map(&:content)]
      document.make_table(row_array, :width => prawn_table.width) do |table|
        table.column_widths = row.map do |field|
          prawn_table.column_widths[field.colspan_range].inject(:+)
        end

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
  end

end
