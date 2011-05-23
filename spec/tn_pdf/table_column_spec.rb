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

      describe "#collection" do
        it "accepts only arrays" do
          column = Table::Column.new(["String", :to_s])
          setting_as_array = Proc.new do
            column.collection = [1,2,3]
          end

          setting_as_non_array = Proc.new do
            column.collection = :not_an_array
          end

          setting_as_array.should change(column, :collection)
          setting_as_non_array.should raise_error
        end
      end

      describe "#values" do
        it "maps #collection values to the underlying proc" do
          column = Table::Column.new(["String", :to_s])
          numbers = (1..3).to_a
          column.collection = numbers
          column.values.should == %w[1 2 3]
        end
      end
    end
  end
end
