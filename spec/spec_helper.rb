# Adds the "lib" dir to the load path
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'tn_pdf'

# Creating 'stub' classes that don't exist yet
class EmptyClass
  def method_missing(method,*args)
    nil
  end
end


classes = %w[PageSection Report Table].map(&:to_sym)

classes.each do |class_name|
  next if TnPDF.const_defined?(class_name)
  TnPDF.const_set(class_name, EmptyClass)
end

require 'prawn'

# Utility methods:

def random_string
  (Time.now.to_f+rand(1000)).to_s
end
