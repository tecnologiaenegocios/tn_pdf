require 'spec_helper'

module TnPDF
  class Table
    const_set("Column",EmptyClass) unless const_defined?("Column")
  end


  describe Table do
    let(:subject)  { Table.new(stub('Document')) }

    describe "#columns_hash" do
      it "is a kind of Hash" do
        subject.columns_hash.should be_kind_of(Hash)
      end

      it "is ordered" do
        subject.add_column ["A", :A]
        subject.add_column ["B", :B]
        subject.add_column ["C", :C]

        subject.columns_hash.keys.should == %w[A B C]
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

      it "adds a supplied column to the columns hash" do
        adding_valid_column = Proc.new do
          subject.add_column(valid_column)
        end
        adding_valid_column.should change(subject.columns, :count).by(1)
      end

      it "should the argument be a column, it adds directly" do
        column = Table::Column.new [ "String", :to_s ]
        subject.add_column(column)
        subject.columns.should include(column)
      end
    end

    describe "#columns_headers" do
      it "returns the columns headers" do
        subject.add_column ["String", :to_s]
        subject.add_column ["Integer", :to_i]
        subject.add_column ["Mean", :mean]

        subject.columns_headers.should == %w[String Integer Mean]
      end
    end

    describe "#rows" do
      it "returns the values of the objects for each column" do
        subject = Table.new(stub('Document')) # Just to be explicit
        subject.add_column( ["String", :to_s] )
        subject.add_column( ["Integer", :to_i] )
        subject.add_column( ["Doubled", Proc.new { |x| x*2 } ] )

        subject.collection = [1, 2, 3]
        subject.rows.should == [ ["1", "1", "2"],
                                 ["2", "2", "4"],
                                 ["3", "3", "6"] ]
      end
    end

    describe "#render" do
      let(:table) do
        mock("Prawn::Table").as_null_object
      end

      let(:document) do
        mock("Prawn::Document").as_null_object
      end

      it "instantiates a Prawn::Table instance" do
        document.should_receive(:make_table).and_return(table)
        subject = Table.new(document)
        subject.render(0)
      end
    end
  end
end
