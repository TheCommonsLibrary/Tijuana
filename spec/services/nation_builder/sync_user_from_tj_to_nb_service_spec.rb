require 'spec_helper'
require 'nationbuilder'

xdescribe NationBuilder::SyncUserFromTjToNbService, delay_jobs: false do

  let!(:nb_api){ NationBuilder::Api }
  let!(:service){ NationBuilder::SyncUserFromTjToNbService.new }

  describe "#sync!" do
    
    context "with a user not matched on email in NationBuilder" do
      let!(:new_user) { 
        user = build :user_with_details
        user.tag_list = 'middledonor , majordonor, notwhitelisted, not sync tag ,a tag [sync]'
        user
      }
      let(:successful_response_from_api){ {"person" => {"id" => 1 }} }
      before{ nb_api.should_receive(:call_api).with(:people, :match, email: new_user.email)
          .and_return({"code"=>"no_matches", "message"=>"No people matched the given criteria."}) }

      it "should call create on the API with all fields" do
        nb_api.should_receive(:call_api){|endpoint, method, params|
          endpoint.should == :people
          method.should == :create
          params[:person][:external_id].should == new_user.id
          params[:person][:email].should == new_user.email
          params[:person][:home_address][:address1].should == new_user.street_address
          params[:person][:home_address][:city].should == new_user.suburb
          params[:person][:home_address][:zip].should == new_user.postcode_number
          params[:person][:home_address][:state].should == new_user.postcode_state
          params[:person][:email_opt_in].should be true
        }.and_return(successful_response_from_api)
        service.sync! new_user
      end

      it "should only sync tags ending in 'sync'" do
        nb_api.should_receive(:call_api){|endpoint, method, params|
          params[:person][:tags].should == ['a tag [sync]']
        }.and_return(successful_response_from_api)
        service.sync! new_user
      end
    end

    context "with a user matched on email in NationBuilder but none of the fields in :only_sync_these_attributes argument need to be synced" do
      let!(:existing_user){ create(:user_with_sync_tag) }
      let!(:year_in_the_future){ Date.today.year + 1 }
      before{ nb_api.should_not_receive(:call_api) }

      it "should NOT call create or update on the API" do
        service.sync! existing_user, only_sync_these_attributes: ['random']
      end
    end

    context "with a user matched on email in NationBuilder but last updated before NationBuilder record" do
      let!(:existing_user){ create(:user_with_sync_tag) }
      let!(:year_in_the_future){ Date.today.year + 1 }
      before{ nb_api.should_receive(:call_api).with(:people, :match, email: existing_user.email)
          .and_return({"person"=>{"updated_at"=>"#{year_in_the_future}-02-16T21:33:26+11:00", "id"=>1}}) }

      it "should NOT call create or update on the API" do
        nb_api.should_not_receive :call_api
        service.sync! existing_user
      end
    end

    context "with a user WITHOUT a sync tag" do
      let!(:user_without_sync_tag) { 
        user = create(:user_with_details)
        user.update_attributes :tag_list => ['tag that does not end with "sync" --']
        user
      }
      let!(:year_in_the_future){ Date.today.year + 1 }

      it "should NOT call create or update on the API" do
        nb_api.should_not_receive :call_api
        service.sync! user_without_sync_tag
      end
    end

    context "with a user matched on email in NationBuilder but the email is not the primary email" do
      let!(:existing_user){ create(:user_with_sync_tag ) }
      let!(:not_matching_email){ 'notmatching@emai.com' }
      let!(:year_in_the_future){ Date.today.year + 1 }
      before{ nb_api.should_receive(:call_api).with(:people, :match, email: existing_user.email)
          .and_return({"person"=>{"updated_at"=>"2015-02-16T21:33:26+11:00", "id"=>1, "email"=> not_matching_email}}) }

      it "should NOT call create or update on the API" do
        service.sync! existing_user
      end
    end

    context "with a user matched on email in NationBuilder but last updated after NationBuilder record" do
      let!(:existing_user){ create(:user_with_sync_tag) }
      let!(:nb_id_for_existing_user){ 111111 }
      let!(:successful_response_from_api){ {"person" => {"id" => nb_id_for_existing_user}} }
      let!(:year_in_the_past){ Date.today.year - 1 }
      before{ nb_api.should_receive(:call_api).with(:people, :match, email: existing_user.email)
          .and_return({"person"=>{"updated_at"=>"#{year_in_the_past}-02-16T21:33:26+11:00", "id"=> nb_id_for_existing_user, "email"=>existing_user.email}}) }

      it "should call update on the API with attributes passed in the :only_sync_these_attributes argument" do
        nb_api.should_receive(:call_api){|endpoint, method, params|
          endpoint.should == :people
          method.should == :update
          params[:id].should == nb_id_for_existing_user
          params[:person].keys.sort.should == [:first_name, :last_name]
          params[:person][:first_name].should == existing_user.first_name
          params[:person][:last_name].should == existing_user.last_name
        }.and_return(successful_response_from_api)
        service.sync! existing_user, only_sync_these_attributes: ['first_name', 'last_name']
      end

      it "should record the NationBuilder ID" do
        nb_api.should_receive(:call_api).with(:people, :update, anything()).and_return(successful_response_from_api)
        NationBuilderUser.should_receive(:record_nationbuilder_id!).with(existing_user.id, nb_id_for_existing_user)
        service.sync! existing_user, only_sync_these_attributes: ['first_name', 'last_name']
      end
    end

    context "with a user with existing NationBuilder ID and last updated after NationBuilder record" do
      let!(:existing_user){ create(:user_with_sync_tag) }
      let!(:existing_nation_builder_user){ create(:nation_builder_user, nationbuilder_id: nb_id_for_existing_user, user: existing_user) }
      let!(:nb_id_for_existing_user){ 123 }
      let!(:successful_response_from_api){ {"person" => {"id" => nb_id_for_existing_user}} }
      let!(:year_in_the_past){ Date.today.year - 1 }
      before{ nb_api.should_receive(:call_api).with(:people, :show, {id: existing_nation_builder_user.nationbuilder_id})
          .and_return({"person"=>{"updated_at"=>"#{year_in_the_past}-02-16T21:33:26+11:00", "id"=> nb_id_for_existing_user, "email"=>existing_user.email}}) }

      it "should call update on the API with attributes passed in the :only_sync_these_attributes argument" do
        nb_api.should_receive(:call_api){|endpoint, method, params|
          endpoint.should == :people
          method.should == :update
          params[:id].should == nb_id_for_existing_user
          params[:person].keys.sort.should == [:first_name, :last_name]
          params[:person][:first_name].should == existing_user.first_name
          params[:person][:last_name].should == existing_user.last_name
        }.and_return(successful_response_from_api)
        service.sync! existing_user, only_sync_these_attributes: ['first_name', 'last_name']
      end
    end

    context "with a NationBuilder API call that throws a error" do
      let!(:existing_user){ create(:user_with_sync_tag) }
      let!(:existing_nation_builder_user){ create(:nation_builder_user, nationbuilder_id: nb_id_for_existing_user, user: existing_user) }
      let!(:nb_id_for_existing_user){ 123 }
      let!(:nationbuilder_error){ 'some error' }
      let(:deliveries) { ActionMailer::Base.deliveries }
      before{ nb_api.should_receive(:call_api).and_raise(NationBuilder::ClientError.new(nationbuilder_error)) }

      it "should email nationbuilder-admins with useful information" do
        deliveries.clear
        service.sync! existing_user, only_sync_these_attributes: ['first_name', 'last_name']
        expect(deliveries.size).to eq(1)
        expect(deliveries[0].to).to eq(['nationbuilder-admins@getup.org.au'])
        expect(deliveries[0].body).to include(existing_user.email)
        expect(deliveries[0].body).to include(nationbuilder_error)
      end
    end
  end

  describe ".disable_sync" do

    it "should disable all syncing within the passed block" do
      nb_api.should_not_receive(:call_api)
      NationBuilder::SyncUserFromTjToNbService.disable_sync do
        service.sync! create(:user_with_sync_tag)
      end
    end

    context "with an exception raised during the sync" do
      it "should reset NationBuilder::SyncUserFromTjToNbService.sync_disabled" do
        expect{
          NationBuilder::SyncUserFromTjToNbService.disable_sync{ raise "fail!" }
        }.to raise_error(RuntimeError, /fail/)
        NationBuilder::SyncUserFromTjToNbService.sync_disabled.should be false
      end
    end
  end

  describe ".max_attempts" do
    it{ expect(service.max_attempts).to eq(2) }
  end

  describe ".reschedule_at" do
    let!(:now){ Time.now }
    context "on first retry attempt" do
      it "should retry in 10 minutes" do
        expect(service.reschedule_at(now, 1).to_date).to eq(now.advance(minutes: 10).to_date)
      end
    end
    context "on last retry attempt" do
      it "should retry in 24 minutes" do
        expect(service.reschedule_at(now, 2).to_date).to eq(now.advance(hours: 24).to_date)
      end
    end
  end
end
