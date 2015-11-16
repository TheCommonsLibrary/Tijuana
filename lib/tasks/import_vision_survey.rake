require 'vision_survey/vision_survey_service'
require 'vision_survey/vision_survey_result_row'
require 'vision_survey/vision_survey_summary_postcode_data_row'

namespace :import do
  desc 'Import 2014 vision survey results - Takes a csv filename as its argument. e.g. 2014_vision_survey_results.csv. Must be stored in db/csv/ directory.'
  task :vision_survey_results, [:vision_survey_results_csv_file] => :environment do |t, args|

    def display_failed_records(failed_records)
      if failed_records.present?
        puts "Total number of imports failed: #{failed_records.count}"
        puts "Following records not imported:"
        failed_records.each {|event_row|  puts event_row}
      end
    end

    failed_records = []
    index = 0
    begin
      CSV.foreach("db/csv/#{args[:vision_survey_results_csv_file]}", :headers => true) do |row|
        begin
          result_row = VisionSurveyResultRow.new(row)
          VisionSurveyService.record_results result_row
          puts "Added result for: #{result_row.user.email}"
        rescue Exception => e
          failed_records << row.to_hash
          puts "Failed to import vision survey result: #{index} - #{e.message}"
        ensure
          index += 1
        end
      end
      display_failed_records(failed_records)
    rescue Exception => e
      puts "The file might contain invalid CSV sequence or non-ascii characters. The file must be fixed before importing otherwise it will fail. Please consult the Tijuana wiki for more information."
      puts e.message
    end
  end

  desc 'Import 2014 Vision Survey Summary Postcode Data - Takes a csv filename as its argument. e.g. 2014_vision_survey_summary_postcode_data.csv. Must be stored in db/csv/ directory.'
  task :vision_survey_summary_postcode_data, [:vision_survey_summary_postcode_data_file] => :environment do |t, args|
    def display_failed_records(failed_records)
      if failed_records.present?
        puts "Total number of imports failed: #{failed_records.count}"
        puts "Following records not imported:"
        failed_records.each {|event_row|  puts event_row}
      end
    end

    failed_records = []
    index = 0
    begin
      CSV.foreach("db/csv/#{args[:vision_survey_summary_postcode_data_file]}", :headers => true) do |row|
        begin
          result_row = VisionSurveySummaryPostcodeDataRow.new(row)
          VisionSurveyService.record_summary_postcode_data result_row
          puts "Added result for: #{result_row.postcode.number}"
        rescue Exception => e
          failed_records << row.to_hash
          puts "Failed to import vision survey summary postcode data: #{index} - #{e.message}"
        ensure
          index += 1
        end
      end
      display_failed_records(failed_records)
    rescue Exception => e
      puts "The file might contain invalid CSV sequence or non-ascii characters. The file must be fixed before importing otherwise it will fail. Please consult the Tijuana wiki for more information."
      puts e.message
    end
  end
end