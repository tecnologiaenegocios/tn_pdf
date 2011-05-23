module TnPDF
  class Report
    attr_reader :page_header, :page_footer, :table, :record_collection

    def initialize
      @page_header = PageSection.new
      @page_footer = PageSection.new
      @table       = Table.new
      @record_collection = Array.new
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
      @record_collection = @table.collection = collection
    end

    def table_columns
      @table.columns || Array.new
    end

    private

    def page_header=(page_header)
      unless page_header.kind_of? PageSection
        raise ArgumentError, "page_header should be a PageSection!"
      end
      @page_header = page_header
    end

    def page_footer=(page_footer)
      unless page_footer.kind_of? PageSection
        raise ArgumentError, "page_footer should be a PageSection!"
      end
      @page_footer = page_footer
    end
  end
end
