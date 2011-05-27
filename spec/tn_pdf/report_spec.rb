require 'spec_helper'

module TnPDF
  const_set("PageSection", EmptyClass) unless const_defined?("PageSection")
  const_set("Table", EmptyClass) unless const_defined?("Table")

  describe Report do

    describe "#page_header and #page_footer" do
      specify "are page sections" do
        subject.page_header.should be_kind_of TnPDF::PageSection
        subject.page_footer.should be_kind_of TnPDF::PageSection
      end

      specify "aren't publicly modifiable" do
        direct_assignment = lambda do
          subject.page_header = :some_section
          subject.page_footer = :some_section
        end
        direct_assignment.should raise_error
      end

      specify "are modifiable by page_header_left and page_footer_left" do
        subject.page_header.should_receive(:left=)
        subject.page_footer.should_receive(:left=)

        subject.page_header_left = { :text => random_string }
        subject.page_footer_left = { :text => random_string }
      end

      specify "are modifiable by page_header_right and page_footer_right" do
        subject.page_header.should_receive(:right=)
        subject.page_footer.should_receive(:right=)

        subject.page_header_right = { :text => random_string }
        subject.page_footer_right = { :text => random_string }
      end

      specify "are modifiable by page_header_center and page_footer_center" do
        subject.page_header.should_receive(:center=)
        subject.page_footer.should_receive(:center=)

        subject.page_header_center = { :text => random_string }
        subject.page_footer_center = { :text => random_string }
      end

    end

    describe "#record_collection" do
      it "is a kind of array" do
        subject.record_collection.should be_kind_of Array
      end

      it "is settable by the record_collection= method" do
        subject.record_collection = [:a, :b, :c]
        subject.record_collection.should == [:a, :b, :c]
      end

      it "doesn't accept non-array arguments" do
        invalid_values = [ Hash.new, :collection, "collection", 123]
        invalid_values.each do |invalid_value|
          setting_invalid_value = lambda do
            subject.record_collection = invalid_value
          end
          setting_invalid_value.should raise_error
        end
      end
    end

    describe "#table_columns" do
      it "is a kind of array" do
        subject.table_columns.should be_kind_of Array
      end
    end

    describe "#table_columns=" do
      it "is a proxy to Table#add_column" do
        subject.table.should_receive(:add_column)

        column = [ [ 'String' , :to_s ] ]
        subject.table_columns = column
      end

      it "works with multiple columns" do
        subject.table.should_receive(:add_column).exactly(3).times

        columns = [ [ 'String' => :to_s] ,
                    [ 'Object id' => :object_id] ,
                    [ 'Name'   => :name] ]
        subject.table_columns = columns
      end
    end

    describe "#document" do
      it "returns the Prawn::Document associated with the report" do
        subject.document.should be_kind_of Prawn::Document
      end
    end

    it "has all the properties defined on Report" do
      Configuration.properties_names do |property|
        subject.should respond_to(property)
        subject.should respond_to(:"#{property}=")
      end
    end

    specify "passing a hash of options on initialization works" do
      properties = { :page_layout => :portrait,
                     :left_margin => 5.cm }
      subject = Report.new(properties)
      subject.page_layout.should == :portrait
      subject.left_margin.should == 5.cm
    end
  end
end
