# Adds the "lib" dir to the load path
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'tn_pdf'

require 'prawn'
