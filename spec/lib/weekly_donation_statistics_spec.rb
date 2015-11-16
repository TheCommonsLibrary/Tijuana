require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")
require 'weekly_donation_statistics'

describe WeeklyDonationStatistics do

  before :each do
    duplicate_user = create(:user)
    @campaign = create(:campaign, name: "Testing campaign")
    @other_campaign = create(:campaign, name: "Testing campaign 2")
    @page_sequence = create(:page_sequence, name: "a page sequence", campaign: @campaign)
    @other_page_sequence = create(:page_sequence, name: "another page sequence", campaign: @other_campaign)
    @very_old_page = create(:page_with_parent, page_sequence: @page_sequence, name: "very old page")
    @old_page = create(:page_with_parent, page_sequence: @page_sequence, name: "old page")
    @new_page = create(:page_with_parent, page_sequence: @other_page_sequence, name: "new page")
    very_old_one_off_transaction = create(:transaction, amount_in_cents: 1000000, created_at: 22.days.ago, donation: create(:donation, created_at: 22.days.ago, frequency: 'one_off', page: @very_old_page))
    very_old_periodic_transaction = create(:transaction, amount_in_cents: 1000000, created_at: 22.days.ago, donation: create(:donation, created_at: 22.days.ago, frequency: 'weekly', page: @very_old_page))
    old_one_off_transaction = create(:transaction, amount_in_cents: 100000, created_at: 8.days.ago, donation: create(:donation, created_at: 8.days.ago, frequency: 'one_off', page: @old_page))
    old_periodic_transaction = create(:transaction, amount_in_cents: 200000, created_at: 8.days.ago, donation: create(:donation, created_at: 8.days.ago, frequency: 'weekly', page: @old_page))
    new_weekly =   create(:transaction, amount_in_cents:      1, donation: create(:donation, frequency: 'weekly', page: @new_page, user: duplicate_user))
    new_monthly =  create(:transaction, amount_in_cents:     10, donation: create(:donation, frequency: 'monthly', page: @new_page, user: duplicate_user))
    new_annual =   create(:transaction, amount_in_cents:    100, donation: create(:donation, frequency: 'annual', page: @new_page))
    new_one_off1 = create(:transaction, amount_in_cents:   1000, donation: create(:donation, frequency: 'one_off', page: @new_page))
    new_one_off2 = create(:transaction, amount_in_cents:  10000, donation: create(:donation, frequency: 'one_off', page: @new_page))
  end

  describe "stats" do

    context "for 1 week" do
      before :each do
        @stats = WeeklyDonationStatistics.from(Time.now, 1)
      end

      it "sums transaction amounts for periodic transactions since start date" do
        @stats.periodic_donations_amount_in_dollars.should == 1.11
      end

      it "sums transaction amounts for one off transactions since start date" do
        @stats.one_off_donations_amount_in_dollars.should == 110.0
      end

      context "donations by page sequence" do
        it "should include the correct page sequence name" do
          @stats.donations_by_page_sequence[@other_page_sequence.id][:name].should == @other_page_sequence.name
        end

        it "should create multiple entries for page sequences with same names but different campaigns" do
          campaign = create(:campaign, name: "Testing campaign")
          another_page_sequence = create(:page_sequence, name: "another page sequence", campaign: campaign)
          page = create(:page_with_parent, page_sequence: another_page_sequence, name: "page")
          create(:transaction, amount_in_cents:  10000, donation: create(:donation, frequency: 'one_off', page: page))

          stats = WeeklyDonationStatistics.from(Time.now, 1)

          stats.donations_by_page_sequence[@other_page_sequence.id].should_not be_nil
          stats.donations_by_page_sequence[another_page_sequence.id].should_not be_nil
        end

        context "pages" do
          it "should include correct page name" do
            @stats.donations_by_page_sequence[@other_page_sequence.id][:pages].should include @new_page.name
            @stats.donations_by_page_sequence[@other_page_sequence.id][:pages].should_not include @old_page.name
            @stats.donations_by_page_sequence[@other_page_sequence.id][:pages].should_not include @very_old_page.name
          end

          it "should return correct amounts for each frequency" do
            @stats.donations_by_page_sequence[@other_page_sequence.id][:pages][@new_page.name][:one_off].should == 110.0
            @stats.donations_by_page_sequence[@other_page_sequence.id][:pages][@new_page.name][:periodic].should == 1.11
          end
        end
        context "totals" do
          it "should return correct amounts for each page sequence" do
            @stats.donations_by_page_sequence[@other_page_sequence.id][:totals][:one_off].should == 110.0
            @stats.donations_by_page_sequence[@other_page_sequence.id][:totals][:periodic].should == 1.11
          end
        end
      end

      context "one_off donations" do
        it "should return donations divided by number of weeks " do
          @stats.one_off_donations_count.should == 2 / 1
        end
      end

      context "new recurring donors" do
        it "should return distinct donors divided by number of weeks " do
          @stats.new_recurring_donor_count.should == 2 / 1
        end
      end

    end

    context "for 3 weeks" do
      before :each do
        @stats = WeeklyDonationStatistics.from(Time.now, 3)
      end

      it "sums transaction amounts for periodic transactions since start date" do
        @stats.periodic_donations_amount_in_dollars.should be_within(0.01).of 667.036 #= (111+200000)/300
      end

      it "averages transaction amounts for one off transactions since start date" do
        @stats.one_off_donations_amount_in_dollars.should be_within(0.01).of 370.0  #= (11000+100000)/300
      end

      context "donations by page sequence" do
        it "should include the correct page sequence name" do
          @stats.donations_by_page_sequence[@other_page_sequence.id][:name].should == @other_page_sequence.name
          @stats.donations_by_page_sequence[@page_sequence.id][:name].should == @page_sequence.name
        end

        context "pages" do
          it "should include correct page name" do
            @stats.donations_by_page_sequence[@other_page_sequence.id][:pages].should include @new_page.name
            @stats.donations_by_page_sequence[@page_sequence.id][:pages].should include @old_page.name
            @stats.donations_by_page_sequence[@page_sequence.id][:pages].should_not include @very_old_page.name
          end

          it "should return correct amounts for each frequency" do
            @stats.donations_by_page_sequence[@other_page_sequence.id][:pages][@new_page.name][:one_off].should == 110.0
            @stats.donations_by_page_sequence[@other_page_sequence.id][:pages][@new_page.name][:periodic].should == 1.11
            @stats.donations_by_page_sequence[@page_sequence.id][:pages][@old_page.name][:one_off].should == 1000.0
            @stats.donations_by_page_sequence[@page_sequence.id][:pages][@old_page.name][:periodic].should == 2000.0
          end
        end

        context "totals" do
          it "should return correct amounts for each page sequence" do
            @stats.donations_by_page_sequence[@other_page_sequence.id][:totals][:one_off].should == 110.00
            @stats.donations_by_page_sequence[@other_page_sequence.id][:totals][:periodic].should == 1.11
            @stats.donations_by_page_sequence[@page_sequence.id][:totals][:periodic].should == 2000.00
            @stats.donations_by_page_sequence[@page_sequence.id][:totals][:one_off].should == 1000.00
          end
        end
      end


      context "count of one_off donations" do
        it "should return donations divided by number of weeks " do
          @stats.one_off_donations_count.should == 3 / 3
        end
      end

      context "new recurring donors" do
        it "should return distinct donors divided by number of weeks " do
          @stats.new_recurring_donor_count.should == 3 / 3
        end
      end

    end

    context 'structure of map' do
      it 'should be sorted in descending order of sum of sub-totals' do
        page_sequence = create(:page_sequence, name: "sort test page sequence", campaign: @campaign)
        page = create(:page_with_parent, page_sequence: page_sequence, name: "newest test order of things page")
        donation = create(:donation, created_at: 8.days.ago, frequency: 'weekly', page: page)
        create(:transaction, amount_in_cents: 9000090, created_at: 8.days.ago, donation: donation)
        stats = WeeklyDonationStatistics.from(Time.now, 4)
        stats.ordered_donation_hash_keys[0].should == page_sequence.id
        stats.ordered_donation_hash_keys[1].should == @page_sequence.id
        stats.ordered_donation_hash_keys[2].should == @other_page_sequence.id
      end
    end
  end
end