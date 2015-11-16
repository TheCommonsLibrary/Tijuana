require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Admin::BlastsController do
  before :each do
    @push = create(:push)
    @valid_params = {
      :name => "Ceci n'est pas une blaste"
    }
    @blast = create(:blast, :push => @push)
    list = create(:list, :blast => @blast)
    list.stub(:filter_by_rules_excluding_users_from_push).and_return([])
    @email = create(:email, :blast => @blast)
    @email.send_test!(['dummy@email.com'])
    # mock up an authentication in the underlying warden library
    @admin = create(:user, :is_admin => true)
    request.env['warden'] = double(Warden, :authenticate => @admin,
                                         :authenticate! => @admin,
                                         :authenticate? => true, :session => @admin)
    Delayed::Worker.new.work_off
    Delayed::Job.count.should eql 0
    Timecop.freeze(Time.local(2012, 1, 1, 12, 0, 0))
  end

  after :each do
    Timecop.return
  end

  without_transactional_fixtures do
    it "should only allow one simultaneous blast in a push" do
      with_push_table do
        post :deliver, :id => @blast.id, :email_id => "all", :limit => 500
        post :deliver, :id => @blast.id, :email_id => "all", :limit => 500
        Delayed::Job.count.should eql 1
        Delayed::Job.first.handler.should include('segment_user_ids_per_job')

        Delayed::Worker.new.work_off
        Delayed::Job.count.should eql 1
        Timecop.travel(Time.local(2012, 1, 1, 12, 10, 0)) do
          Delayed::Worker.new.work_off #blastjob
        end
        Delayed::Job.count.should eql 0

        post :deliver, :id => @blast.id, :email_id => "all", :limit => 500
        Delayed::Job.count.should eql 1
      end
    end

    context "with another push in progress" do
      render_views
      let!(:concurrent_push){ create(:push) }
      let!(:concurrent_blast){ create(:blast, push: concurrent_push) }
      let!(:list){ create(:list, blast: concurrent_blast) }
      let!(:concurrent_email){ create(:email, blast: concurrent_blast) }
      before do
        list.stub(:filter_by_rules_excluding_users_from_push).and_return([])
        concurrent_email.send_test!(['dummy@email.com'])
        post :deliver, id: @blast.id, email_id: "all", limit: 500
      end

      it "should prevent the send from occuring" do
        post :deliver, id: concurrent_blast.id, email_id: "all", limit: 500
        expect(response).to be_redirect
      end
    end
  end
end
