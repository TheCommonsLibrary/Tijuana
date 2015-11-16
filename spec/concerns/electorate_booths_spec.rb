require 'spec_helper'

describe ElectorateBooths do

  describe "#target_electorate" do
    let(:user){ create(:user, postcode: postcode) }

    context "with a user multiple electorates" do
      let!(:most_populous_electorate){ create(:sydney_federal, jurisdiction: create(:federal_jurisdiction, id: 9)) }
      let(:postcode){ create(:postcode, electorates: [most_populous_electorate, create(:sydney_federal_second)]) }
      before{ make_most_populous(postcode, most_populous_electorate) }
      
      it "should choose the most populuous one" do
        expect(user.target_electorate).to eq(most_populous_electorate.name)
      end
    end

    context "with no electorates" do
      let(:postcode){ nil }

      it "should return nil" do
        expect(user.target_electorate).to be_nil
      end
    end
  end

  describe "#target_electorate_mp" do
    let(:user){ create(:user, postcode: postcode) }

    context "with a user multiple electorates" do
      let!(:most_populous_electorate){ create(:sydney_federal, jurisdiction: create(:federal_jurisdiction, id: 9)) }
      let!(:most_populous_electorate_mp){ create(:mp, electorate: most_populous_electorate) }
      let(:postcode){ create(:postcode, electorates: [most_populous_electorate, create(:sydney_federal_second)]) }
      before{ make_most_populous(postcode, most_populous_electorate) }
      
      it "should choose the MP from the most populuous one" do
        expect(user.target_electorate_mp).to eq(most_populous_electorate_mp.full_name)
      end
    end

    context "with no electorates" do
      let(:postcode){ nil }

      it "should return nil" do
        expect(user.target_electorate_mp).to be_nil
      end
    end
  end

  describe "#target_electorate_slug" do
    let(:user){ create(:user, postcode: postcode) }

    context "with a user multiple electorates" do
      let(:postcode){ create(:postcode, electorates: [most_populous_electorate, create(:sydney_federal_second)]) }

      context "in a target electorate" do
        let(:most_populous_electorate){ create(:sydney_federal, name: 'Eden-Monaro Test', issue: Issue.create!(seat: 'Sydney'), jurisdiction: create(:federal_jurisdiction, id: 9)) }
        before{ make_most_populous(postcode, most_populous_electorate) }

        it "should create a slug for the electorate" do
          expect(user.target_electorate_slug).to eq('eden-monaro_test')
        end
      end
      context "NOT in a target electorate but in a target state" do
        let(:most_populous_electorate){ create(:sydney_federal, name: 'Eden-Monaro Test', jurisdiction: create(:federal_jurisdiction, id: 9)) }
        before{ make_most_populous(postcode, most_populous_electorate) }

        it "should return the state" do
          expect(user.target_electorate_slug).to eq('nsw_renewables')
        end
      end

      context "NOT in a target electorate and NOT in a target state" do
        let(:most_populous_electorate){ create(:sydney_federal, jurisdiction: create(:federal_jurisdiction, id: 9)) }
        let(:postcode){ create(:postcode, state: 'NT', electorates: [most_populous_electorate, create(:sydney_federal_second)]) }

        it "should nil" do
          expect(user.target_electorate_slug).to be_nil
        end
      end
    end
  end

  describe "#volunteer_at_booths" do
    include SendgridTokenReplacement

    describe "with an email with a volunteer_at_booths MERGE token" do
      let(:eval_code){ "volunteer_at_booths('booth_data_key',email.id)" }
      let(:eval_code_for_only_links){ "volunteer_at_booths('booth_data_key',email.id,link_only:true)" }
      let(:merge_token){ "{MERGE:#{eval_code}|}" }
      let(:merge_token_for_only_links){ "{MERGE:#{eval_code_for_only_links}|}" }
      let(:email){ create(:email_with_tokens, body: "<p>hi #{merge_token}</p><p>#{merge_token_for_only_links} ") }
      let(:recipient){ create(:user) }
      let(:options){ {test: true, recipients: [recipient.email]} }
      let(:token){ EmailTrackingToken.encode(recipient.id, email.id) }
      before do
        Setting[:whitelist_merge_tokens] = "postcode_id\n#{eval_code}\n#{eval_code_for_only_links}"
      end

      context "with no matching electorate data" do
        it "should return nil" do
          expect(get_substitutions_list(email, options)[merge_token_for_only_links]).to eq([
            "<p><a href='http://www.getup.org.au/electionday?t=#{token}'>Volunteer at a booth near you</a></p>"
          ])
        end
      end

      context "with electorate data matching the recipients postcode" do
        let!(:postcode){ create(:postcode, number: '2454') }
        let!(:cowper_electorate) { create(:electorate, name: 'Cowper', jurisdiction: create(:federal_jurisdiction), postcodes: [postcode]) }
        let!(:test_electorate) { create(:electorate, name: 'Test in postcode 2454', jurisdiction: cowper_electorate.jurisdiction, postcodes: [postcode]) }
        let!(:merge){ create(:merge, name: 'booth_data_key', join_field_name: 'ELECTORATE', join_key: 'postcode_id') }
        before do
          recipient.postcode = postcode
          recipient.save!
          MergeUploader.create_merge_records?(merge, File.open("#{Rails.root}/spec/fixtures/files/electorate_booth_links.csv"))
        end
        
        it "should return a list of buttons for each electorate" do
          expect(get_substitutions_list(email, options)[merge_token]).to eq([
            "<p><a href='http://www.getup.org.au/bellingen-anglican-church-hall?t=#{token}' style='background-color:#FA4B18;margin:2px;border:12px solid #FA4B18;border-radius:7px;display:inline-block;font-family:sans-serif;font-size:20px;font-weight:bold;line-height:25px;text-align:center;text-decoration:none;width:400px;color:#ffffff;letter-spacing:2px;-webkit-text-size-adjust:none;'>Volunteer at Bellingen Anglican Church Hall</a></p>" +
            "<p><a href='http://www.getup.org.au/cowper-test-booth?t=#{token}' style='background-color:#FA4B18;margin:2px;border:12px solid #FA4B18;border-radius:7px;display:inline-block;font-family:sans-serif;font-size:20px;font-weight:bold;line-height:25px;text-align:center;text-decoration:none;width:400px;color:#ffffff;letter-spacing:2px;-webkit-text-size-adjust:none;'>Volunteer at Cowper Test Booth</a></p>" +
            "<p><a href='http://www.getup.org.au/2454-test-booth?t=#{token}' style='background-color:#FA4B18;margin:2px;border:12px solid #FA4B18;border-radius:7px;display:inline-block;font-family:sans-serif;font-size:20px;font-weight:bold;line-height:25px;text-align:center;text-decoration:none;width:400px;color:#ffffff;letter-spacing:2px;-webkit-text-size-adjust:none;'>Volunteer at Test 2454 booth</a></p>"
          ])
        end
        
        it "should return a list of links for each electorate" do
          expect(get_substitutions_list(email, options)[merge_token_for_only_links]).to eq([
            "<p><a href='http://www.getup.org.au/bellingen-anglican-church-hall?t=#{token}'>Volunteer at Bellingen Anglican Church Hall</a></p>" +
            "<p><a href='http://www.getup.org.au/cowper-test-booth?t=#{token}'>Volunteer at Cowper Test Booth</a></p>" +
            "<p><a href='http://www.getup.org.au/2454-test-booth?t=#{token}'>Volunteer at Test 2454 booth</a></p>"
          ])
        end

        context "with split passed" do
          let(:eval_code){ "volunteer_at_booths('booth_data_key',email.id,split:0.5,link_only:true)" }
          let(:merge_token){ "{MERGE:#{eval_code}|}" }
          let(:email){ create(:email_with_tokens, body: "<p>hi #{merge_token}</p>") }

          it "should select split the buttons into two exclusive halfs and randomly return one of them" do
            recipient.update_attributes!(random: 0.24)
            expect(get_substitutions_list(email, options)[merge_token]).to eq([
              "<p><a href='http://www.getup.org.au/bellingen-anglican-church-hall?t=#{token}'>Volunteer at Bellingen Anglican Church Hall</a></p>" +
              "<p><a href='http://www.getup.org.au/cowper-test-booth?t=#{token}'>Volunteer at Cowper Test Booth</a></p>"
            ])
            recipient.update_attributes!(random: 0.9)
            expect(get_substitutions_list(email, options)[merge_token]).to eq([
              "<p><a href='http://www.getup.org.au/2454-test-booth?t=#{token}'>Volunteer at Test 2454 booth</a></p>"
            ])
          end
        end

        context "with a user with an electorate but no match to a merge" do
          let!(:postcode_without_a_matching_electorate){ create(:postcode, number: '2454') }
          let!(:another_electorate) { create(:sydney_federal, postcodes: [postcode_without_a_matching_electorate]) }
          before{
            recipient.postcode = postcode_without_a_matching_electorate
            recipient.save!
          }

          it "should return nil" do
            expect(get_substitutions_list(email, options)[merge_token_for_only_links]).to eq([
              "<p><a href='http://www.getup.org.au/electionday?t=#{token}'>Volunteer at a booth near you</a></p>"
            ])
          end
        end
      end
    end
  end

  def make_most_populous(postcode, electorate)
    ActiveRecord::Base.connection.execute("update electorates_postcodes set population=1 where electorate_id = #{electorate.id} and postcode_id = #{postcode.id}")
  end
end
