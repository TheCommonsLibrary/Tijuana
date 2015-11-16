require 'spec_helper'
require 'google/apis/gmail_v1'

describe Gmail::LabelService do

  describe ".label_new_messages" do

    context "with VCR turned off" do
      let!(:user){ create(:user, email: 'b.j.rossiter@gmail.com', postcode: create(:postcode, number: '2348', state: 'NSW')) }
      let!(:donation){ create(:transaction, donation: create(:donation, user: user)) }
      let!(:recurring_donation){ create(:transaction, donation: create(:recurring_donation, user: user)) }
      let!(:actions){ 10.times{ create(:petition_action, user: user) } }
      let(:message_id){ '1538859d2cc6e6a4' }

      it 'should work against a real email in the info-dev@getup.org.au account' do
        # Delete the tags for the email from B.J. with subject 'test subject'
        # and then uncomment below. Password for the account is in lastpass

         #WebMock.allow_net_connect!
         #VCR.turned_off { Gmail::LabelService.label_new_messages }
         #WebMock.disable_net_connect!

        # check the info-dev mailbox for the labels
      end
    end

    context "with the gmail apis mocked out" do
      let!(:user){ create(:user) }
      let!(:message_id){ '1' }
      let!(:mocked_client){ double }
      let!(:mocked_message){ double }

      before do
        GmailApi::GmailService.stub(:new).and_return(mocked_client)
        Google::Auth.stub(:get_application_default).and_return(double.as_null_object)
        mocked_client.stub(:authorization=)
        mocked_client.stub_chain(:list_user_messages, :messages).and_return([double(id: message_id)])
        mocked_client.stub(:get_user_message).and_return(mocked_message)
        mocked_message.stub_chain(:payload, :headers).and_return([double(name: 'From', value: "#{user.name} <#{user.email}>"), double(name: 'Subject', value: "Thanks for writing to us! RE: #{defined?(email) && email.subject}")])
        mocked_client.stub_chain(:list_user_labels, :labels).and_return([double(name: label_name, id: 'Label_1'), double(name: 'processed', id: 'Label_2')])
      end

      context "with an email with no matching member" do
        let!(:label_name){ 'nothing important' }

        it 'should just set the processed label' do
          user.destroy!
          expect(mocked_client).to receive(:modify_message){|user_id, message_id, modify_request|
            expect(user_id).to eq('me')
            expect(message_id).to eq(message_id)
            expect(modify_request.add_label_ids).to eq(['Label_2'])
          }
          Gmail::LabelService.label_new_messages
        end
      end

      context "with an email for a one-off donor" do
        let!(:donation){ create(:transaction, donation: create(:donation, user: user)) }
        let!(:label_name){ 'donor' }

        it 'should set the "donor" label' do
          expect(mocked_client).to receive(:modify_message){|user_id, message_id, modify_request|
            expect(user_id).to eq('me')
            expect(message_id).to eq(message_id)
            expect(modify_request.add_label_ids).to eq(['Label_1', 'Label_2'])
          }
          Gmail::LabelService.label_new_messages
        end
      end

      context "with an email for a one-off donor of $250 or more" do
        let!(:donation){ create(:transaction, donation: create(:donation, user: user, amount_in_cents: 25000)) }
        let!(:label_name){ 'middle-donor' }

        it 'should set the "middle-donor" label' do
          expect(mocked_client).to receive(:modify_message){|user_id, message_id, modify_request|
            expect(user_id).to eq('me')
            expect(message_id).to eq(message_id)
            expect(modify_request.add_label_ids).to eq(['Label_1', 'Label_2'])
          }
          Gmail::LabelService.label_new_messages
        end
      end


      context "with an email for a recurring donor" do
        let!(:donation){ create(:transaction, donation: create(:recurring_donation, user: user)) }
        let!(:label_name){ 'recurring' }

        it 'should set the "recurring" label' do
          expect(mocked_client).to receive(:modify_message){|user_id, message_id, modify_request|
            expect(modify_request.add_label_ids).to eq(['Label_1', 'Label_2'])
          }
          Gmail::LabelService.label_new_messages
        end
      end

      context "with an email for an active member" do
        let!(:actions){ 10.times{ create(:petition_action, user: user) } }
        let!(:label_name){ 'active' }

        it 'should set the "active" label' do
          expect(mocked_client).to receive(:modify_message){|user_id, message_id, modify_request|
            expect(modify_request.add_label_ids).to eq(['Label_1', 'Label_2'])
          }
          Gmail::LabelService.label_new_messages
        end
      end

      context "with an email for a member in a primary target electorate " do
        let!(:user){ create(:user, postcode: create(:postcode)) }
        let!(:primary_electorate){ create(:electorate, name: 'Bass') }
        let!(:label_name){ 'primary' }
        before{ primary_electorate.postcodes << user.postcode }

        it 'should set the "primary" label' do
          expect(mocked_client).to receive(:modify_message){|user_id, message_id, modify_request|
            expect(modify_request.add_label_ids).to eq(['Label_1', 'Label_2'])
          }
          Gmail::LabelService.label_new_messages
        end
      end

      context "with an email that matches the subject line of a recent email" do
        let!(:campaign){ create(:campaign, name: 'A name with a space at end ') }
        let!(:label_name){ "campaigns/#{campaign.name.downcase.strip}" }
        let!(:email){ create(:email, subject: "you won't believe what happened..", blast: create(:blast, push: create(:push, campaign: campaign))) }

        it 'should set the label to match the campaign name' do
          expect(mocked_client).to receive(:modify_message){|user_id, message_id, modify_request|
            expect(modify_request.add_label_ids).to eq(['Label_1', 'Label_2'])
          }
          Gmail::LabelService.label_new_messages
        end

        context "with a deleted push" do
          let!(:second_campaign){ create(:campaign, name: 'second campaign') }
          let!(:second_label_name){ "campaigns/#{second_campaign.name}" }
          let!(:second_email){ create(:email, created_at: 1.second.since(email.created_at), subject: "you won't believe what happened..", blast: create(:blast, push: create(:push, campaign: second_campaign))) }
          before do
            second_email.blast.push.destroy!
          end

          it 'should set the label to match the campaign name' do
            expect(mocked_client).to receive(:modify_message){|user_id, message_id, modify_request|
              expect(modify_request.add_label_ids).to eq(['Label_1', 'Label_2'])
            }
            Gmail::LabelService.label_new_messages
          end
        end
      end

      context "with an email that matches the email of an admin user" do
        let!(:user){  create(:admin_user) }
        let!(:donation){ create(:transaction, donation: create(:donation, user: user)) }
        let!(:label_name){ 'donor' }

        it 'should set only the processed label' do
          expect(mocked_client).to receive(:modify_message){|user_id, message_id, modify_request|
            expect(modify_request.add_label_ids).to eq(['Label_2'])
          }
          Gmail::LabelService.label_new_messages
        end
      end

      context "with an email that only has an email address in the from field" do
        let!(:donation){ create(:transaction, donation: create(:donation, user: user)) }
        let!(:label_name){ 'donor' }
        before do
          mocked_message.stub_chain(:payload, :headers).and_return([double(name: 'From', value: "#{user.email}"), double(name: 'Subject', value: "RE: #{defined?(email) && email.subject}")])
        end

        it 'should set the processed and donor labels' do
          expect(mocked_client).to receive(:modify_message){|user_id, message_id, modify_request|
            expect(modify_request.add_label_ids).to eq(['Label_1', 'Label_2'])
          }
          Gmail::LabelService.label_new_messages
        end
      end

      context "with an email that has a malformed address in the from field" do
        let!(:donation){ create(:transaction, donation: create(:donation, user: user)) }
        let!(:label_name){ 'donor' }
        before do
          mocked_message.stub_chain(:payload, :headers).and_return([double(name: 'From', value: "#{user.email} <#{user.first_name}>"), double(name: 'Subject', value: "RE: #{defined?(email) && email.subject}")])
        end

        it 'should still set the processed and donor labels' do
          expect(mocked_client).to receive(:modify_message){|user_id, message_id, modify_request|
            expect(modify_request.add_label_ids).to eq(['Label_1', 'Label_2'])
          }
          Gmail::LabelService.label_new_messages
        end
      end

      context "with an email that is a missing from header" do
        let!(:donation){ create(:transaction, donation: create(:donation, user: user)) }
        let!(:label_name){ 'donor' }
        before do
          mocked_message.stub_chain(:payload, :headers).and_return([double(name: 'Subject', value: "RE: #{defined?(email) && email.subject}")])
        end

        it 'should ignore the email but set the processed label' do
          expect(mocked_client).to receive(:modify_message){|user_id, message_id, modify_request|
            expect(modify_request.add_label_ids).to eq(['Label_2'])
          }
          Gmail::LabelService.label_new_messages
        end
      end

      context "with a label that doesn't exist" do
        let!(:donation){ create(:transaction, donation: create(:donation, user: user)) }
        let!(:label_name){ 'donor' }

        it 'should create the label and set it on the email' do
          mocked_client.stub_chain(:list_user_labels, :labels).and_return([double(name: 'processed', id: 'Label_2')])
          expect(mocked_client).to receive(:create_user_label){|user_id, gmail_label|
            expect(user_id).to eq('me')
            expect(gmail_label.name).to eq('donor')
          }.and_return(double(id: 'Label_1'))
          expect(mocked_client).to receive(:modify_message){|user_id, message_id, modify_request|
            expect(user_id).to eq('me')
            expect(message_id).to eq(message_id)
            expect(modify_request.add_label_ids).to eq(['Label_1', 'Label_2'])
          }
          Gmail::LabelService.label_new_messages
        end
      end
    end
  end

  describe ".label_volunteer_messages" do
    context "with the gmail apis mocked out" do
      let!(:user){ create(:user) }
      let!(:message_id){ '1' }
      let!(:mocked_client){ double }
      let!(:mocked_message){ double }

      before do
        GmailApi::GmailService.stub(:new).and_return(mocked_client)
        Google::Auth.stub(:get_application_default).and_return(double.as_null_object)
        mocked_client.stub(:authorization=)
        mocked_client.stub_chain(:list_user_messages, :messages).and_return([double(id: message_id)])
        mocked_client.stub(:get_user_message).and_return(mocked_message)
        mocked_message.stub_chain(:payload, :headers).and_return([double(name: 'From', value: "#{user.name} <#{user.email}>"), double(name: 'Subject', value: "RE: #{defined?(email) && email.subject}")])
        mocked_client.stub_chain(:list_user_labels, :labels).and_return([double(name: label_name, id: 'Label_1'), double(name: 'processed', id: 'Label_2')])
      end

      context "with an email with no matching member" do
        let!(:user){ create(:user) }
        let!(:label_name){ 'unknown electorate' }

        it "should label with processed and unknown electorate" do
          user.destroy!
          expect(mocked_client).to receive(:modify_message){|user_id, message_id, modify_request|
            expect(modify_request.add_label_ids).to eq(['Label_1', 'Label_2'])
          }
          Gmail::LabelService.label_volunteer_messages
        end
      end

      context "with an email address with a known electorate" do
        let!(:user){ create(:user, postcode: create(:postcode)) }
        let!(:electorate){ create(:electorate, name: 'Bass', jurisdiction: create(:federal_jurisdiction)) }
        let!(:label_name){ 'electorates/bass' }
        before{ electorate.postcodes << user.postcode }

        it "should label the email with the electorate and a generic label" do
          expect(mocked_client).to receive(:modify_message){|user_id, message_id, modify_request|
            expect(modify_request.add_label_ids).to eq(['Label_1', 'Label_2'])
          }
          Gmail::LabelService.label_volunteer_messages
        end

        it "should tag the member with the electorate and a generic label" do
          expect(mocked_client).to receive(:modify_message){|user_id, message_id, modify_request|
            expect(modify_request.add_label_ids).to eq(['Label_1', 'Label_2'])
          }
          Gmail::LabelService.label_volunteer_messages
          user.reload
          expect(user.tag_list).to eq(['electorates/bass', 'electorate_volunteer'])
        end
      end

      context "with an email address with an unknown electorate" do
        let!(:user){ create(:user, postcode: create(:postcode)) }
        let!(:label_name){ 'unknown electorate' }

        it "should label the email with an unknown label" do
          expect(mocked_client).to receive(:modify_message){|user_id, message_id, modify_request|
            expect(modify_request.add_label_ids).to eq(['Label_1', 'Label_2'])
          }
          Gmail::LabelService.label_volunteer_messages
        end

        it "should tag the member with electorate volunteer" do
          expect(mocked_client).to receive(:modify_message){|user_id, message_id, modify_request|
            expect(modify_request.add_label_ids).to eq(['Label_1', 'Label_2'])
          }
          Gmail::LabelService.label_volunteer_messages
          user.reload
          expect(user.tag_list).to eq([label_name, 'electorate_volunteer'])
        end
      end
    end
  end

  context "on the delayed job queue" do
    it 'should just set the max attempts to 5' do
      expect(Gmail::LabelService.max_attempts).to eq(5)
    end
  end

  describe ".label_new_messages_if_not_scheduled" do
    it "should create a delayed job for running .label_new_messages" do
      Gmail::LabelService.label_new_messages_if_not_scheduled
      expect(Delayed::Job.where("handler like '%label_new_messages%'").count).to eq(1)
    end

    context "with a job already on the queue" do
      before{ Gmail::LabelService.label_new_messages_if_not_scheduled }
      it "should not create another job" do
        Gmail::LabelService.label_new_messages_if_not_scheduled
        expect(Delayed::Job.where("handler like '%label_new_messages%'").count).to eq(1)
      end
    end
  end

  describe ".label_volunteer_messages_if_not_scheduled" do
    it "should create a delayed job for running .label_volunteer_messages" do
      Gmail::LabelService.label_volunteer_messages_if_not_scheduled
      expect(Delayed::Job.where("handler like '%label_volunteer_messages%'").count).to eq(1)
    end

    context "with a job already on the queue" do
      before{ Gmail::LabelService.label_volunteer_messages_if_not_scheduled }
      it "should not create another job" do
        Gmail::LabelService.label_volunteer_messages_if_not_scheduled
        expect(Delayed::Job.where("handler like '%label_volunteer_messages%'").count).to eq(1)
      end
    end
  end
end
