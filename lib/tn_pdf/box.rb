module TnPDF
  class PageSection

    class Box
      attr_reader :image_path, :image_options
      attr_reader :text, :text_options

      def initialize(options)
        parse_options(options)
      end

      def render(document, width, pos)
        document.bounding_box(pos, :width => width) do
          if has_image?
            image_args = [image_path]
            image_args << image_options unless image_options.empty?
            document.image *image_args
          end

          if has_text?
            text_args = [text]
            text_args << text_options unless text_options.empty?
            document.text *text_args
          end
        end
      end

      def has_image?
        !image_path.nil?
      end

      def has_text?
        !text.nil?
      end

      private

      def parse_options(options)
        options.to_options!

        if options[:text]
          unless options[:text].kind_of? Hash
            options[:text] = { :text => options[:text] }
          end
          @text = options[:text][:text]
          @text_options = options[:text].reject { |k,_| k == :text }
        end

        if options[:image]
          unless options[:image].kind_of? Hash
            options[:image] = { :path => options[:image] }
          end
          @image_path = options[:image][:path]
          @image_options = options[:image].reject { |k,_| k == :path }
        end
      end

    end
  end
end
