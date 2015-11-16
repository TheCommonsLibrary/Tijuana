require 'spec_helper'

describe NationBuilder::SyncUserFromNbToTjService, delay_jobs: false do

  let!(:service){ NationBuilder::SyncUserFromNbToTjService.new }

  describe "#sync!" do

    context "with update person payload and at least one sync tag" do
      let(:nationbuilder_id){ 99 }
      let(:nationbuilder_tags_to_sync){ ['first [sync]', 'second_sync'] }
      let(:nationbuilder_tags_to_ignore){ ['ignore', 'contain sync but ignored'] }
      let(:external_id){ nil }
      let(:existing_postcode) { create :postcode }
      let(:nb_user){ {
        "id"=> nationbuilder_id,
        "email"=> email,
        "external_id" => external_id,
        "tags"=> (nationbuilder_tags_to_sync + nationbuilder_tags_to_ignore),
        "first_name" => "first",
        "last_name" => "last",
        "mobile" => "0123456789",
        "phone" => "9876543210",
        "email_opt_in" => false,
        "home_address" => {
          'address1' => 'dummy address',
          'city' => 'dummy city',
          'state' => existing_postcode.state,
          'zip' => existing_postcode.number.to_s,
          'country_code' => 'AU',
        }
      }}
      let(:payload){ {payload: {person: nb_user}}.with_indifferent_access }

      context "with no user with a matching email" do
        let!(:email){ 'nomatch@email.com' }
        before { NationBuilderSyncLog.should_receive(:create!).with(hash_including(endpoint: 'person_changed')) }
        let(:created_user){ User.find_by_email(email) }
        before{ service.sync! payload }

        it "should create the user in tijuana" do
          user_should_match_payload created_user
        end

        it "should put them on low volume" do
          created_user.should be_low_volume
        end

        it "should create user's subscription activity event" do
          created_user.user_activity_events.should_not be_empty
          created_user.user_activity_events.last.public_stream_html.should =~ /created by Nation Builder/
        end
      end

      context "with a user matching on external_id" do
        let!(:email){ 'new-email@test.com' }
        let!(:matching_user){ create :user, postcode: create(:postcode) }
        let!(:external_id){ matching_user.id }
        let!(:nationbuilder_sync_user_after_save){ nil }
        let!(:existing_nation_builder_user){ matching_user.create_nation_builder_user!(nationbuilder_id: 111) }
        before do
          if nationbuilder_sync_user_after_save
            AppConstants.stub(:nationbuilder_sync_user_after_save).and_return(true)
          end
          service.sync! payload
          matching_user.reload
        end

        specify{ NationBuilderSyncLog.count.should == 1 }

        it "should update user's details" do
          user_should_match_payload matching_user
        end

        it "should update the user's email" do
          expect(matching_user.email).to eq(email)
        end
      end

      context "with a user matching on email" do
        let!(:email){ 'matching-user@test.com' }
        let!(:matching_user){ create :user, email: email, postcode: create(:postcode) }
        let!(:nationbuilder_sync_user_after_save){ nil }
        let!(:existing_nation_builder_user){ nil }
        before do
          if nationbuilder_sync_user_after_save
            AppConstants.stub(:nationbuilder_sync_user_after_save).and_return(true)
          end
          service.sync! payload
          matching_user.reload
        end

        specify{ NationBuilderSyncLog.count.should == 1 }

        it "should update user's details" do
          user_should_match_payload matching_user
        end

        it "should record the NationBuilder ID" do
          NationBuilderUser.should_receive(:record_nationbuilder_id!).with(matching_user.id, nationbuilder_id)
          service.sync! payload
        end

        context "with AppConstants.nationbuilder_sync_user_after_save = true" do
          let!(:nationbuilder_sync_user_after_save){ true }

          it "should NOT sync user back to NB" do
            NationBuilder::Api.should_not_receive(:call_api)
          end
        end

        it "should not create new user activity events" do
          matching_user.user_activity_events.length.should == 1
        end
      end
    end

    context "with a payload for a NB user with no email" do
      let(:nationbuilder_id){ 99 }
      let(:nationbuilder_tags_to_sync){ ['first [sync]', 'second_sync'] }
      let(:nationbuilder_tags_to_ignore){ ['ignore', 'contain sync but ignored'] }
      let(:existing_postcode) { create :postcode }
      let(:nb_user){ {
        "id"=> nationbuilder_id,
        "email"=> '',
        "tags"=> (nationbuilder_tags_to_sync + nationbuilder_tags_to_ignore),
        "first_name" => "first",
        "last_name" => "last",
        "mobile" => "0123456789",
      }}
      let(:payload){ {payload: {person: nb_user}}.with_indifferent_access }

      context "with no user with a matching email" do
        let!(:email){ 'nomatch@email.com' }

        it "should NOT try to create a user" do
          expect{ service.sync!(payload) }.to_not change{User.count}
        end
      end
    end

    context "with a nationbuilder record with empty fields" do
      let(:existing_user){ create(:user_with_details) }
      let(:nb_user){ {
        "id"=> 111,
        "email"=> existing_user.email,
        "tags"=> ['test_sync'],
        "first_name" => "",
        "last_name" => "",
      }}
      let(:payload){ {payload: {person: nb_user}}.with_indifferent_access }

      it "should not overwrite existing fields with blank data" do
        service.sync!(payload)
        existing_user.reload
        expect(existing_user.first_name).to_not be_blank
        expect(existing_user.last_name).to_not be_blank
      end
    end

    context "with a nationbuilder record that matches an admin user" do
      let(:admin_user){ create(:admin_user) }
      let(:nb_user){ {
        "id"=> 111,
        "email"=> admin_user.email,
        "tags"=> ['test_sync'],
        "first_name" => "hacked?",
      }}
      let(:payload){ {payload: {person: nb_user}}.with_indifferent_access }

      it "should not overwrite existing fields with blank data" do
        service.sync!(payload)
        admin_user.reload
        expect(admin_user.first_name).to_not eq('hacked?')
      end
    end

    context "with update person payload and blank tags" do
      let(:email){ 'test@test.com' }
      let(:nb_user){ {
        "id"=> 10,
        "email"=> email,
        "tags"=> nil,
        "first_name" => "first",
        "last_name" => "last"
      }}
      let(:payload){ {payload: {person: nb_user}}.with_indifferent_access }

      context "with no user with a matching email" do
        it "should NOT try to create a user" do
          expect{ service.sync!(payload) }.to_not change{User.count}
        end
      end
    end

    context "with update person payload and no sync tags" do
      let(:email){ 'test@test.com' }
      let(:nb_user){ {
        "id"=> 10,
        "email"=> email,
        "tags"=> ['no sync tags'],
        "first_name" => "first",
        "last_name" => "last"
      }}
      let(:payload){ {payload: {person: nb_user}}.with_indifferent_access }

      context "with no user with a matching email" do
        it "should NOT try to create a user" do
          expect{ service.sync!(payload) }.to_not change{User.count}
        end
      end

      context "with matching user" do
        let!(:matching_user){ create(:user_with_details, email: email) }

        it "should NOT update the user" do
          expect{ service.sync!(payload); matching_user.reload }.to_not change{ matching_user.first_name }
        end
      end
    end

    context "with a payload for a NB user with no matching postcode" do
      let(:nationbuilder_id){ 99 }
      let(:nationbuilder_tags_to_sync){ ['first [sync]', 'second_sync'] }
      let(:nationbuilder_tags_to_ignore){ ['ignore', 'contain sync but ignored'] }
      let(:nb_user){ {
        "id"=> nationbuilder_id,
        "email"=> 'test@test.com',
        "tags"=> (nationbuilder_tags_to_sync + nationbuilder_tags_to_ignore),
        "first_name" => "first",
        "last_name" => "last",
        "mobile" => "0123456789",
        "home_address" => {
          'address1' => 'dummy address',
          'city' => 'dummy city',
          'zip' => '4096',
          'state' => 'QLD',
          'country_code' => 'AU',
        }
      }}
      let(:payload){ {payload: {person: nb_user}}.with_indifferent_access }

      it "should create the user without a postcode" do
        expect{ service.sync!(payload) }.to change{User.count}
      end
    end

    context "with a user that has had their primary email updated in NationBuilder" do
      let(:nationbuilder_id){ 99 }
      let(:user_with_old_email){ create(:leo) }
      let(:user_already_with_new_email){ create(:leo, email: "new-#{user_with_old_email.email}") }
      let(:nb_user){ {
        "id"=> nationbuilder_id,
        "email"=> user_already_with_new_email.email,
        "tags"=> ['first sync'],
        "first_name" => "first",
        "last_name" => "last",
        "mobile" => "0123456789",
        "home_address" => {
          'address1' => 'dummy address',
          'city' => 'dummy city',
          'zip' => '4096',
          'state' => 'QLD',
          'country_code' => 'AU',
        },
        external_id: user_with_old_email.id
      }}
      let(:payload){ {payload: {person: nb_user}}.with_indifferent_access }
      let(:deliveries) { ActionMailer::Base.deliveries }

      it 'should send an informative email to nation builder admins' do
        deliveries.clear
        service.sync!(payload)
        expect(deliveries.size).to eq(1)
        expect(deliveries[0].to).to eq(['nationbuilder-admins@getup.org.au'])
        expect(deliveries[0].body).to include(user_with_old_email.email)
        expect(deliveries[0].body).to include(user_already_with_new_email.email)
      end
    end

    context 'with delayed_jobs turned on' do
      before{ Delayed::Worker.delay_jobs = true }
      let(:nb_user){ {
        "id"=> 99,
        "email"=> "test@example.com",
        "tags"=> ["tag_sync"]
      }}
      let(:payload){ {payload: {person: nb_user}}.with_indifferent_access }
      it 'should be on the "nationbuilder_api" queue' do
        service.sync!(payload)
        expect(Delayed::Job.where(queue: 'nationbuilder_api').length).to eq(1)
      end
    end
  end


  private

  def user_should_match_payload(matching_user)
    matching_user.first_name.should == "first"
    matching_user.last_name.should == "last"
    matching_user.mobile_number.should == "0123456789"
    matching_user.home_number.should == "9876543210"
    matching_user.street_address.should == "dummy address"
    matching_user.suburb.should == "dummy city"
    matching_user.postcode_number.should == existing_postcode.number
    matching_user.postcode_state.should == existing_postcode.state
    matching_user.country_iso.should == "AU"
    matching_user.is_member.should be false
    matching_user.tag_list.should == ["first [sync]", "second_sync"]
  end
end
