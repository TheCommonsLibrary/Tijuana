#!/usr/bin/env ruby

require 'CSV'

class PushTablesToCSV
  def initialize(input_file, output_file)
    @successes = []
    @failures = []
    if ARGV.length == 2
      build_output(input_file)
      write_file(output_file)
      print_results
    else
      puts 'Usage: ./push_tables_to_csv.rb [inputFile] [outputFile]'
    end
  end

end

if $PROGRAM_NAME == __FILE__
  PushTablesToCSV.new(ARGV[0], ARGV[1])
end
# ./push_tables_to_csv.rb