require 'spec_helper'
require 'vision_survey/vision_survey_service'
require 'vision_survey/vision_survey_result_row'
require 'vision_survey/vision_survey_summary_postcode_data_row'

describe VisionSurveyService do
  describe "#record_results" do
    it 'should import the results correctly into VisionSurveyResult' do
      User.find_or_create_by_email('user281@email123.com')
      csv_string = %q[dXNlcmlkPTEwNTgxNzUsZW1haWxpZD00MjQx,user281@email123.com,5,4,5,4,5,1 Top Priority,6 Low Priority,4,5,4,1 Top Priority,2,3,5,Climate,1,,I'm a photographer and can take some photos at local events,I'd love to be an extra and feature in one of your ads or videos,,,,,,I have some storage space you could use to store campaign materials like placards/posters/stickers,,,,,,Send Info,Yes,I don't use Facebook,I use YouTUbe and I subscribe to GetUpAus,I use Twitter and I follow @GetUp,I have a blog,I don't use Google+,1,"Use this survey as a strong guide, but continue to stay nimble and adapt our plans to keep current with breaking news and events."]
      csv_rows = CSV.parse(csv_string)

      result_row = VisionSurveyResultRow.new(csv_rows.first)
      VisionSurveyService.record_results result_row

      vision_survey_result = VisionSurveyResult.first
      vision_survey_result.user.email.should == 'user281@email123.com'
      vision_survey_result.new_details_supplied.should be true
      vision_survey_result.q4_priority_issue.should == 'climate'
      vision_survey_result.q7_volunteering_open_text.should be_nil
      vision_survey_result.q8_bequest.should be true
      vision_survey_result.q9_major_donor.should be true
      vision_survey_result.q10_facebook.should == 'no'
      vision_survey_result.q11_youtube.should == 'subscribe'
      vision_survey_result.q12_twitter.should == 'follow'
      vision_survey_result.q13_blogging.should == 'haveblog'
      vision_survey_result.q14_google.should == "no"
      vision_survey_result.q18_transparency.should == 'guide'

      issues = vision_survey_result.vision_survey_q3_priority_issues
      issues.count.should == 4
      issues[0].name.should == 'climate'
      issues[1].name.should == 'forests'
      issues[2].name.should == 'csg'
      issues[3].name.should == 'marriage'

      skills = vision_survey_result.vision_survey_q6_skills
      skills.count.should == 3
      skills[0].name.should == "I'm a photographer and can take some photos at local events"
      skills[1].name.should == "I'd love to be an extra and feature in one of your ads or videos"
      skills[2].name.should == 'I have some storage space you could use to store campaign materials like placards/posters/stickers'
    end

    it 'should not import the result if the user does not exist and throw an exception' do
      csv_string = %q[dXNlcmlkPTEwNTgxNzUsZW1haWxpZD00MjQx,user281@email123.com,5,4,5,4,5,1 Top Priority,6 Low Priority,4,5,4,1 Top Priority,2,3,5,Climate,1,,I'm a photographer and can take some photos at local events,I'd love to be an extra and feature in one of your ads or videos,,,,,,I have some storage space you could use to store campaign materials like placards/posters/stickers,,,,,,Send Info,Yes,I don't use Facebook,I use YouTUbe and I subscribe to GetUpAus,I use Twitter and I follow @GetUp,I have a blog,I don't use Google+,1,"Use this survey as a strong guide, but continue to stay nimble and adapt our plans to keep current with breaking news and events."]
      csv_rows = CSV.parse(csv_string)

      result_row = VisionSurveyResultRow.new(csv_rows.first)
      expect {VisionSurveyService.record_results result_row}.to raise_exception(RuntimeError, /Unable to find user with email/)
      VisionSurveyResult.first.should be_nil
    end
  end

  describe '#record_summary_postcode_data' do
    it 'should import the summary data correctly into VisionSurveyDataByPostcode' do
      Postcode.create(number: 2000, longitude: 149.117, latitude: -35.2773)
      csv_string = %q[1,2000,1,NULL,NULL,339]
      csv_rows = CSV.parse(csv_string)

      summary_data_row = VisionSurveySummaryPostcodeDataRow.new(csv_rows.first)
      VisionSurveyService.record_summary_postcode_data summary_data_row

      summary_data = VisionSurveyDataByPostcode.first
      summary_data.postcode.number.should == '2000'
      summary_data.climate_rallies.should == 1
      summary_data.election_volunteers.should == 0
      summary_data.booths_covered.should == 0
      summary_data.num_of_members.should == 339

      Postcode.delete_all
    end

    it 'should not import the summary data if the postcode does not exist and throw an exception' do
      csv_string = %q[1,2000,1,NULL,NULL,339]
      csv_rows = CSV.parse(csv_string)

      summary_data_row = VisionSurveySummaryPostcodeDataRow.new(csv_rows.first)
      expect{VisionSurveyService.record_summary_postcode_data summary_data_row}.to raise_exception(/Unable to find postcode 2000/)

      VisionSurveyDataByPostcode.first.should be_nil
    end

    it 'should find a postcode with a number missing the leading zero' do
      Postcode.create(number: '0800', longitude: 149.117, latitude: -35.2773)
      csv_string = %q[1,800,1,NULL,NULL,339]
      csv_rows = CSV.parse(csv_string)

      summary_data_row = VisionSurveySummaryPostcodeDataRow.new(csv_rows.first)
      VisionSurveyService.record_summary_postcode_data summary_data_row

      summary_data = VisionSurveyDataByPostcode.first
      summary_data.postcode.number.should == '0800'
      summary_data.climate_rallies.should == 1
      summary_data.election_volunteers.should == 0
      summary_data.booths_covered.should == 0
      summary_data.num_of_members.should == 339

      Postcode.delete_all
    end
  end
end
