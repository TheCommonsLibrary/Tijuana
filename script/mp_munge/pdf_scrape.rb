require 'rubygems'
require 'pdf-reader'

reader = PDF::Reader.new("MemList.pdf")
reader.pages.each do |page|
  puts page.text
end

