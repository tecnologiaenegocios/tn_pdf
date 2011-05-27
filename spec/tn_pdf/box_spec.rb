require 'spec_helper'

module TnPDF
  class PageSection

    describe Box do

      subject { Box.new( {} ) }

      describe "creation options" do
        it "accept texts and/or images" do
          assigning_nice_values = lambda do
            Box.new( { :text  => "text" } )
            Box.new( { :image => "image.jpg" } )
            Box.new( { :text  => "text", :image => "image.jpg" } )
          end
          assigning_nice_values.should_not raise_error
        end

        it "accepts extra text options to prawn by passing hashes" do
          document = Prawn::Document.new
          box = Box.new( :text => {:text => "text", :font => "DejaVu Sans"} )

          document.should_receive(:text).with("text", hash_including(:font => "DejaVu Sans") )
          box.render(document, [0,0], 100)
        end

        it "accepts extra image options to prawn by passing hashes" do
          document = Prawn::Document.new
          box = Box.new( :image => {:path => "image.jpg", :width => 1.cm } )

          document.should_receive(:image).with("image.jpg", hash_including(:width => 1.cm) )
          box.render(document, [0,0], 100)
        end
      end

      describe "#render" do
        let(:document) { Prawn::Document.new }

        it "creates a bounding box on the provided document" do
          document.should_receive(:bounding_box).with([0,0], hash_including(:width => 20.cm) )
          subject.render(document, [0,0], 20.cm)
        end

        specify "when the box contains text, the text is rendered" do
          subject = Box.new({ :text => "some text" })

          document.should_receive(:text).with("some text", anything())
          subject.render(document, [0, 0], 20.cm)
        end
      end
    end
  end
end
