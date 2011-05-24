require 'tn_pdf/table_column'
require 'prawn'

module TnPDF
  class Table

    def columns
      @columns ||= Array.new
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

    def to_prawn(document)
      document.make_table([columns_headers]+rows)
    end
  end
end
