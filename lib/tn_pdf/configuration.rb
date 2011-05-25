module TnPDF

  class Report
    def Report.defaults
      { :page_size => "A4",
        :page_orientation => :landscape,
        :left_margin => 1.cm,
        :right_margin => 1.cm,
        :top_margin => 1.cm,
        :bottom_margin => 1.cm }
    end

    def Report.properties_names
      defaults.keys
    end
  end
end
