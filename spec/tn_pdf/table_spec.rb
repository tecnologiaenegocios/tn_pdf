require 'spec_helper'

module TnPDF
  class Table
    const_set("Column",EmptyClass) unless const_defined?("Column")
  end

  describe Table do
    describe "#columns" do
      it "is a kind of Array" do
        subject.columns.should be_kind_of(Array)
      end
    end

    describe "#collection" do
      it "is a kind of Array" do
        subject.collection.should be_kind_of(Array)
      end

      it "is settable, as long as the parameter is also an Array" do
        setting_good_parameter = Proc.new do
          subject.collection = [:a, :b, :c]
        end
        setting_good_parameter.should_not raise_error
        subject.collection.should == [:a, :b, :c]
      end

      it "raises an error if someone tries to set it as a non-array" do
        setting_bad_parameter = Proc.new do
          subject.collection = :not_an_array
        end
        setting_bad_parameter.should raise_error
        subject.collection.should_not == :not_an_array
      end
    end

    describe "#add_column" do
      let(:valid_column) { column = ["String", :to_s] }

      before do
        Table::Column.stub(:new)
      end

      it "adds a supplied column to the columns array" do
        adding_valid_column = Proc.new do
          subject.add_column(valid_column)
        end
        adding_valid_column.should change(subject.columns, :count).by(1)
      end

    end
  end
end
