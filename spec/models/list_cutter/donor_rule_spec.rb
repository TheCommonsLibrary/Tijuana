require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe ListCutter::DonorRule do
  describe "validation" do

    it "should validate donation frequency" do
      rule = ListCutter::DonorRule.new

      rule.valid?.should be false
      rule.errors[:frequencies].first.should =~ /Please specify a frequency/
    end

    it "should validate campaign ids numerical" do
      rule = ListCutter::DonorRule.new(frequencies: ['one_off'], campaign_ids: "invalid")
      rule.valid?.should be false
      rule.errors[:campaign_ids].first.should =~ /numbers only/
    end

    it "should validate page ids numerical" do
      rule = ListCutter::DonorRule.new(frequencies: ['one_off'], page_ids: "invalid")
      rule.valid?.should be false
      rule.errors[:page_ids].first.should =~ /numbers only/
    end

    it "should validate campaign ids exist" do
      rule = ListCutter::DonorRule.new(frequencies: ['one_off'], campaign_ids: "99999")
      rule.valid?.should be false
      rule.errors[:campaign_ids].first.should =~ /Invalid campaign id/
    end

    it "should validate page ids exist" do
      rule = ListCutter::DonorRule.new(frequencies: ['one_off'], page_ids: "99999")
      rule.valid?.should be false
      rule.errors[:page_ids].first.should =~ /Invalid page id/
    end
  end

  context "to_relation" do
    before :each do
      @page1 = create(:page, page_sequence: create(:page_sequence, name: "Dummy page-sequence1", campaign: create(:campaign, name: "Dummy campaign1")))
      @page2 = create(:page, page_sequence: create(:page_sequence, name: "Dummy page-sequence2", campaign: create(:campaign, name: "Dummy campaign2")))

      @donation_one_off_for_page1 = create(:donation, :frequency => "one_off", page: @page1)
      @donation_one_off_for_page2 = create(:donation, :frequency => "one_off", page: @page2)

      @donation_weekly_1 = create(:donation, :frequency => "weekly")
      @donation_monthly_1 = create(:donation, :frequency => "monthly")
    end

    context "create_is_relation" do

      it "should call create_is_relation" do
        rule = ListCutter::DonorRule.new(frequencies: [:one_off] , page_ids: "", campaign_ids: "", active: true)

        rule.should_receive(:create_is_relation)
        rule.to_relation
      end

      it "should create relation which select users who are active donors for selected frequencies" do
        frequencies = ['one_off', 'weekly']
        rule = ListCutter::DonorRule.new(frequencies: frequencies , page_ids: "", campaign_ids: "", active: true)
        result = rule.to_relation

        user_ids = result.map(&:id)
        user_ids.size.should == 3
        user_ids.should include(@donation_one_off_for_page1.user.id, @donation_one_off_for_page2.user.id, @donation_weekly_1.user.id)
      end

      it "should create relation which select users who are active donors for given page ids and selected frequencies" do
        page_ids = "#{@page1.id},#{@page2.id}"
        rule = ListCutter::DonorRule.new(frequencies: ['one_off'], page_ids: "#{page_ids}", campaign_ids: "", active: true)
        result = rule.to_relation

        user_ids = result.map(&:id)
        user_ids.size.should == 2
        user_ids.should include(@donation_one_off_for_page1.user.id, @donation_one_off_for_page2.user.id)
      end

      it "should create relation which select users who are active donors for given campaign ids and selected frequencies" do
        campaign_ids = "#{@page1.page_sequence.campaign.id},#{@page2.page_sequence.campaign.id}"
        rule = ListCutter::DonorRule.new(frequencies: ['one_off'], page_ids: "", campaign_ids: campaign_ids, active: true)
        result = rule.to_relation

        user_ids = result.map(&:id)
        user_ids.size.should == 2
        user_ids.should include(@donation_one_off_for_page1.user.id, @donation_one_off_for_page2.user.id)
      end

      it "should create relation which select users who are active donors for given campaign ids, page ids and selected frequencies" do
        campaign_ids = "#{@page2.page_sequence.campaign.id}"
        page_ids = "#{@page1.id}"
        rule = ListCutter::DonorRule.new(:frequencies => ['one_off'], page_ids: page_ids, campaign_ids: campaign_ids, active: true)
        result = rule.to_relation

        user_ids = result.map(&:id)
        user_ids.size.should == 2
        user_ids.should include(@donation_one_off_for_page1.user.id, @donation_one_off_for_page2.user.id)
      end

      context 'active for recurring' do
        it "should create relation which select users that are active donor for selected recurring frequencies" do
          frequencies = ['monthly', 'weekly']
          rule = ListCutter::DonorRule.new(frequencies: frequencies , page_ids: "", campaign_ids: "", active: true)
          result = rule.to_relation

          user_ids = result.map(&:id)
          user_ids.size.should == 2
          user_ids.should include(@donation_monthly_1.user.id, @donation_weekly_1.user.id)
        end

        it "should create relation which select users are not active donor for selected recurring frequencies" do
          @donation_weekly_not_active = create(:donation, :frequency => "weekly", active: false)
          frequencies = ['monthly', 'weekly']
          rule = ListCutter::DonorRule.new(frequencies: frequencies , page_ids: "", campaign_ids: "", active: "0")
          result = rule.to_relation

          user_ids = result.map(&:id)
          user_ids.size.should == 1
          user_ids.should include(@donation_weekly_not_active.user.id)
        end

        it "should create relation which ignore active for one_off donation" do
          @donation_one_off_not_active = create(:donation, :frequency => "one_off", active: false)
          frequencies = ['one_off']
          rule = ListCutter::DonorRule.new(frequencies: frequencies , page_ids: "", campaign_ids: "", active: "0")
          result = rule.to_relation

          user_ids = result.map(&:id)
          user_ids.size.should == 3
          user_ids.should include(@donation_one_off_not_active.user.id, @donation_one_off_for_page1.user.id, @donation_one_off_for_page2.user.id)
        end
      end
    end

    context "create_is_not_relation" do

      it "should call create_is_not_relation" do
        rule = ListCutter::DonorRule.new(frequencies: ['one_off'] , page_ids: "", campaign_ids: "", not: true, active: true)

        rule.should_receive(:create_is_not_relation)
        rule.to_relation
      end

      it "should create relation that exclude users who are active donors for selected frequencies" do
        frequencies = ['one_off', 'weekly']
        rule = ListCutter::DonorRule.new(frequencies: frequencies , page_ids: "", campaign_ids: "", not: true, active: true)
        result = rule.to_relation

        user_ids = result.map(&:id)
        user_ids.size.should == 1
        user_ids.should include(@donation_monthly_1.user.id)
      end

      it "should create relation that exclude users who are active donors for given page ids and selected frequencies" do
        page_ids = "#{@page1.id},#{@page2.id}"
        rule = ListCutter::DonorRule.new(frequencies: ['one_off'], page_ids: "#{page_ids}", campaign_ids: "", not: true, active: true)
        result = rule.to_relation

        user_ids = result.map(&:id)
        user_ids.size.should == 2
        user_ids.should include(@donation_weekly_1.user.id, @donation_monthly_1.user.id)
      end

      it "should create relation that exclude users who are active donors for given campaign ids and selected frequencies" do
        campaign_ids = "#{@page1.page_sequence.campaign.id},#{@page2.page_sequence.campaign.id}"
        rule = ListCutter::DonorRule.new(frequencies: ['one_off'], page_ids: "", campaign_ids: campaign_ids, not: true, active: true)
        result = rule.to_relation

        user_ids = result.map(&:id)
        user_ids.size.should == 2
        user_ids.should include(@donation_weekly_1.user.id, @donation_monthly_1.user.id)
      end

      it "should create relation that exclude users who are active donors for given campaign ids, page ids and selected frequencies" do
        campaign_ids = "#{@page2.page_sequence.campaign.id}"
        page_ids = "#{@page1.id}"

        rule = ListCutter::DonorRule.new(:frequencies => ['one_off'], page_ids: page_ids, campaign_ids: campaign_ids, not:true, active: true)
        result = rule.to_relation

        user_ids = result.map(&:id)
        user_ids.size.should == 2
        user_ids.should include(@donation_weekly_1.user.id, @donation_monthly_1.user.id)
      end

      context 'active for recurring' do
        it "should create relation which select users that are active donor for selected recurring frequencies" do
          frequencies = ['monthly', 'weekly']
          rule = ListCutter::DonorRule.new(frequencies: frequencies , page_ids: "", campaign_ids: "", not: true, active: true)
          result = rule.to_relation

          user_ids = result.map(&:id)
          user_ids.size.should == 2
          user_ids.should include(@donation_one_off_for_page1.user.id, @donation_one_off_for_page2.user.id)
        end

        it "should create relation which select users are not active donor for selected recurring frequencies" do
          @donation_weekly_not_active = create(:donation, :frequency => "weekly", active: false)
          frequencies = ['monthly', 'weekly']
          rule = ListCutter::DonorRule.new(frequencies: frequencies , page_ids: "", campaign_ids: "", active: false, not: true)
          result = rule.to_relation

          user_ids = result.map(&:id)
          user_ids.size.should == 4
          user_ids.should_not include(@donation_weekly_not_active.user.id)
        end
      end

    end
  end
end


