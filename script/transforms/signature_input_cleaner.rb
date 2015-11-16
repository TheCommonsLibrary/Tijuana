#!/usr/bin/env ruby

require 'CSV'

class SignatureInputCleaner
  def initialize(input_file, output_file)
    @successes = []
    @failures = []
    if ARGV.length == 2
      build_output(input_file)
      write_file(output_file)
      print_results
    else
      puts 'Usage: ./signature_input_cleaner.rb [inputFile] [outputFile]'
    end
  end

  def build_output(input_file)
    CSV.open(input_file, 'r').each do |row|
      read_row(row)
    end
  end

  def read_row(row)
    email = extract_email(row)
    phone = extract_phone(row)
    postcode = extract_postcode(row)
    if email.empty? || phone.empty? || postcode.empty?
      @failures << ",,#{email},#{phone},#{postcode}"
    else
      @successes << ",,#{email},#{phone},#{postcode}"
    end
  end

  def extract_phone(row)
    text = row[1].strip
    /([\d])+/.match(text).to_s
  end

  def extract_email(row)
    text = row[2].strip
    /([^\s])+[\@]([^\s])+/.match(text).to_s.downcase
  end

  def extract_postcode(row)
    text = row[2].strip
    /([\d]){4}/.match(text).to_s.downcase
  end

  def write_file(output_file)
    File.open(output_file, 'w') do |line|
      @successes.each { |row| line.puts row }
    end
  end

  def print_results
    puts "successes: #{@successes.size}"
    @successes.each do |row|
      puts row
    end
    puts ''
    puts "failures: #{@failures.size}"
    @failures.each do |row|
      puts row
    end
    puts ''
    puts "total: #{@failures.size + @successes.size}, failures: #{@failures.size}, successes: #{@successes.size}"
  end
end

if $PROGRAM_NAME == __FILE__
  SignatureInputCleaner.new(ARGV[0], ARGV[1])
end
# ./signature_input_cleaner.rb