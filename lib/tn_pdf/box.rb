module TnPDF
  class PageSection

    class Box
      attr_reader :image_file, :image_options
      attr_reader :text, :text_options
      attr_accessor :width

      def initialize(options)
        parse_options(options)
      end

      def render(document, pos, height=nil)
        options_hash = { :width => width }
        options_hash[:height] = height unless height.nil?

        document.bounding_box(pos, options_hash) do
          if has_image?
            image_args = [image_file]
            image_args << image_options unless image_options.empty?
            document.image *image_args
          end

          if has_text?
            text_args = [text]
            text_args << text_options unless text_options.empty?
            document.font(text_options[:font], text_options[:font_options]) do
              document.text *text_args
            end
          end
        end
      end

      def has_image?
        !image_file.nil?
      end

      def has_text?
        !text.nil?
      end

      private

      def parse_options(options)
        options = Configuration.perform_conversions(options)

        self.width = options[:width]
        options[:align]  ||= :justify
        options[:valign] ||= :center

        if options[:text]
          unless options[:text].kind_of? Hash
            options[:text] = { :text => options[:text] }
          end
          options[:text][:align]  = options[:align]
          options[:text][:valign] = options[:valign]

          options[:text][:font] ||= Configuration[:font]
          options[:text][:font_options] = {}
          options[:text][:font_options][:size] =
            options[:text][:font_size] if options[:text][:font_size]

          options[:text][:font_options][:style] =
            options[:text][:font_style] if options[:text][:font_style]

          @text = options[:text][:text]
          @text_options = options[:text].reject { |k,_| k == :text }
        end

        if options[:image]
          unless options[:image].kind_of? Hash
            options[:image] = { :file => options[:image] }
          end
          options[:image][:position] = options[:align]
          options[:image][:vposition] = options[:valign]

          path = Configuration[:images_path]
          @image_file = options[:image][:file]
          unless @image_file =~ /^#{path}/
            @image_file = File.join(path, @image_file)
          end
          @image_options = options[:image].reject { |k,_| k == :file }
        end
      end

    end
  end
end
