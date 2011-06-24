module Prawn
  class Table
    alias_method :column_widths_broken=, :column_widths=

    def column_widths_fixed=(value)
      @column_widths = (column_widths_broken = value)
    end

    alias_method :column_widths=, :column_widths_fixed=
  end
end
