module TnPDF
  class PageSection
    attr_reader :left, :right, :center
    attr_reader :left_box, :center_box, :right_box
    attr_accessor :width, :height

    def left=(options)
      @left = options
      @left_box = Box.new(options)
    end

    def center=(options)
      @center = options
      @center_box = Box.new(options)
    end

    def right=(options)
      @right = options
      @right_box = Box.new(options)
    end

    def boxes
      [left_box, center_box, right_box].compact
    end

    def render(document, position)
      width ||= document.bounds.width

      box_width = width/(boxes.count)
      boxes.inject(0) do |offset, box|
        x_pos = position[0] + offset
        y_pos = position[1]
        box.render(document, [x_pos, y_pos], box_width, height )
        offset += box_width
      end
    end

  end
end
