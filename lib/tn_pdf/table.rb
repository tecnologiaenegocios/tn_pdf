require 'tn_pdf/table_column'

module TnPDF
  class Table

    def columns
      @columns ||= Array.new
    end

    def collection
      @collection ||= Array.new
    end

    def collection=(collection)
      raise ArgumentError unless collection.kind_of? Array
      @collection = collection
    end

    def add_column(column_args)
      column = Column.new(column_args)
      columns << column_args
    end

    private

  end
end
