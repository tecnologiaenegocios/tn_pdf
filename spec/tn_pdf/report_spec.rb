require 'spec_helper'

module TnPDF
  const_set("PageSection", EmptyClass)
  const_set("Table", EmptyClass)

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

      specify "can't be changed by modifying the return value" do
        return_value = subject.page_header
        class << return_value
          define_method(:blah) {}
        end
        return_value.should respond_to(:blah)
        subject.page_header.should_not respond_to(:blah)
      end

      specify "are modifiable by page_header_left and page_footer_left" do
        using_the_methods = lambda do
          subject.page_header_left = { :text => random_string }
          subject.page_footer_left = { :text => random_string }
        end
        using_the_methods.should change(subject, :page_header)
        using_the_methods.should change(subject, :page_footer)
      end

      specify "are modifiable by page_header_center and page_footer_center" do
        using_the_methods = lambda do
          subject.page_header_center = { :text => random_string }
          subject.page_footer_center = { :text => random_string }
        end
        using_the_methods.should change(subject, :page_header)
        using_the_methods.should change(subject, :page_footer)
      end

      specify "are modifiable by page_header_right and page_footer_right" do
        using_the_methods = lambda do
          subject.page_header_right = { :text => random_string }
          subject.page_footer_right = { :text => random_string }
        end
        using_the_methods.should change(subject, :page_header)
        using_the_methods.should change(subject, :page_footer)
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

      it "maps to the underlying table's collection" do
        table = subject.instance_variable_get("@table")
        table.should_receive(:collection=)
        subject.record_collection = [:a, :b, :c]
      end
    end

    describe "#table_columns" do
      # The behaviour needs to be instrusive, because of the
      # high encapsulation level of the object.
      let(:subject_table) { subject.instance_variable_get("@table") }

      it "is a kind of array" do
        subject.table_columns.should be_kind_of Array
      end

      it "maps to the underlying table's columns" do
        subject_table.should_receive(:columns)
        subject.table_columns
      end
    end
  end
end
