# Adds the "lib" dir to the load path
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'tn_pdf'

# Used to 'stub' needed classes that doesn't exist (yet)
class EmptyClass
  def method_missing(method,*args)
    nil
  end
end

require 'prawn'

# Utility methods:

def random_string
  (Time.now.to_f+rand(1000)).to_s
end
