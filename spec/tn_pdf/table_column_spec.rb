require 'spec_helper'

module TnPDF
  class Table
    describe Column do

      context "to be valid, needs a parameter that is" do

        specify "an Array" do
          creating_bad_column = Proc.new { Table::Column.new :not_an_array }
          creating_bad_column.should raise_error ArgumentError
        end

        specify "an Array whose 1st member can be coerced into a String" do
          bad_string = /not_a_string/
            class << bad_string
              undef_method(:to_s)
            end
          creating_bad_column = Proc.new { Table::Column.new [bad_string, :to_s] }
          creating_bad_column.should raise_error ArgumentError
        end

        specify "an Array whose 2nd member can be coerced into a Proc" do
          bad_columns = [["String", "to_s"], ["String", 3], ["String", /to_s/]]
          bad_columns.each do |bad_column|
            creating_bad_column = Proc.new { Table::Column.new bad_column }
            creating_bad_column.should raise_error ArgumentError
          end
        end
      end

      describe "#header" do
        it "returns the string value that was passed as parameter" do
          column_args = ["String", :to_s]
          column = Table::Column.new(column_args)
          column.header.should == "String"
        end
      end

      describe "#to_proc" do
        it "returns the proc that was passed as parameter" do
          my_proc = Proc.new { |object| object.to_s }
          column  = Table::Column.new([123, my_proc])
          column.to_proc.should == my_proc
        end
      end

      describe "#values_for" do
        it "maps received values to the underlying proc" do
          column = Table::Column.new(["String", :to_s])
          numbers = (1..3).to_a
          column.values_for(numbers).should == %w[1 2 3]
        end
      end

      describe "#value_for" do
        it "maps received object to the underlying proc" do
          column = Table::Column.new(["String", :to_s])
          column.value_for(25).should == "25"
        end
      end
    end
  end
end
