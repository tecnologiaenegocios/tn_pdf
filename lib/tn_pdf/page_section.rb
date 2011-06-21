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
      [left_box, center_box, right_box]
    end

    def top
      @top ||= 0
    end

    def bottom
      @bottom ||= 0
    end

    def render(document, position)
      width ||= document.bounds.width

      box_width = width/(boxes.compact.count)

      boxes.each do |box|
        puts box.width
        box.width ||= box_width
      end

      boxes_with_positions = [
        boxes,
        [position[0], (width-boxes[1].width)/2, width-boxes[2].width],
        [position[1]-top]*3
      ].transpose

      boxes_with_positions.each do |box, x_pos, y_pos|
        box.render(document, [x_pos, y_pos], height )
      end
    end

  end
end
