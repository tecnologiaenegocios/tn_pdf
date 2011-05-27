module TnPDF
  class PageSection
    attr_reader :left, :right, :center
    attr_reader :left_box, :center_box, :right_box
    attr_writer :top, :bottom
    attr_accessor :width, :height

    def left=(options)
      @left = options
      options[:align] = :left
      @left_box = Box.new(options)
    end

    def center=(options)
      @center = options
      options[:align] = :center
      @center_box = Box.new(options)
    end

    def right=(options)
      @right = options
      options[:align] = :right
      @right_box = Box.new(options)
    end

    def total_height
      height + top + bottom
    end

    def boxes
      [left_box, center_box, right_box].compact
    end

    def top
      @top ||= 0
    end

    def bottom
      @bottom ||= 0
    end

    def render(document, position)
      width ||= document.bounds.width

      box_width = width/(boxes.count)

      boxes.inject(0) do |offset, box|
        x_pos = position[0] + offset
        y_pos = position[1] - top
        box.render(document, [x_pos, y_pos], box_width, height )
        offset += box_width
      end
    end

  end
end
