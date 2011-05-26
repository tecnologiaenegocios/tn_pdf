require 'spec_helper'

module TnPDF

  describe PageSection do

    describe "its left, center and right parts" do
      let(:parts) { [:left, :center, :right] }

      specify "exist and can be set" do
        parts.each do |part|
          subject.should respond_to(part)
          subject.should respond_to(:"#{part}=")
        end
      end

      specify "are accessible as hashes, and also as boxes" do
        parts.each do |part|
          subject.send("#{part}=", {} )
          subject.send("#{part}").should be_kind_of Hash
          subject.send("#{part}_box").should be_kind_of PageSection::Box
        end
      end
    end

    describe "#render" do
      let(:document) { Prawn::Document.new }

      it "renders each of the defined boxes on the provided document" do
        subject.left   = {:text => "Blah"}
        subject.center = {:text => "Blah"}
        subject.right  = {:text => "Blah"}

        subject.left_box.should_receive(:render)
        subject.center_box.should_receive(:render)
        subject.right_box.should_receive(:render)

        subject.render(document, [0, 0])
      end

      it "divides the available width between the defined boxes" do
        subject.left   = {:text => "Blah"}
        subject.right  = {:text => "Blah"}

        subject.left_box.should_receive(:render).with(
          document, [0, 0], document.bounds.width/2, nil)

        subject.render(document, [0, 0])


        subject = PageSection.new
        subject.left = {:text => "Blah"}

        subject.left_box.should_receive(:render).with(
          document, [0, 0], document.bounds.width, nil)

        subject.render(document, [0, 0])
      end

      it "translates the second and third boxes to the right" do
        subject.left   = {:text => "Blah"}
        subject.center = {:text => "Blah"}
        subject.right  = {:text => "Blah"}

        box_width = document.bounds.width/3
        subject.left_box.should_receive(:render).with(
          document, [0, 0], box_width, nil)

        subject.center_box.should_receive(:render).with(
          document, [box_width, 0], box_width, nil)

        subject.right_box.should_receive(:render).with(
          document, [box_width*2, 0], box_width, nil)

        subject.render(document, [0, 0])
      end
    end
  end
end
