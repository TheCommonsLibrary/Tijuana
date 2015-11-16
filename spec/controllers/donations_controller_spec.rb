require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe DonationsController do

  let :anonymously_updatable_attributes do
    {
        'card_number' => PaymentGateways::CARD_SUCCESS,
        'name_on_card' => "New Name",
        'card_expiry_month' => 2.month.from_now.month.to_s,
        'card_expiry_year' => 2.year.from_now.year.to_s,
        'card_cvv' => "987",
    }
  end

  let :updatable_attributes do
    anonymously_updatable_attributes.merge (
      {
        'frequency' => "weekly",
        'amount_in_dollars' => "50"
      }
    )
  end

  let :user do create(:user) end
  let :donation do create(:donation, frequency: 'weekly', user: user) end

  context "with logged in user" do

    before :each do
      sign_in user
    end

    describe "update" do

      it "updates own credit card and donation frequency details on recurring donation" do
        Donation.should_receive(:find).with(donation.id.to_s).and_return(donation)
        DonationService.any_instance.should_receive(:update_recurring_trigger!).with(donation, updatable_attributes).and_return(true)
        put :update, id: donation.id, :donation => { donation.id.to_s => updatable_attributes}
        response.should be_success
      end

      it "does not update active donation" do
        other_donation = create(:donation, frequency: 'weekly', user: create(:user))
        other_donation.stub(:can_update_anonymously?).and_return(false)

        Donation.stub(find: other_donation)
        DonationService.any_instance.should_not_receive(:update_recurring_trigger!)
        put :update, id: other_donation.id, :donation => { other_donation.id.to_s => updatable_attributes}
        response.should_not be_success
        response.body.should match /Permission denied/
      end

      it "updates expiring/failed donation" do
        other_donation = create(:donation, frequency: 'weekly', user: create(:user))
        other_donation.stub(:can_update_anonymously?).and_return(true)
        Donation.should_receive(:find).with(other_donation.id.to_s).and_return(other_donation)
        DonationService.any_instance.should_receive(:update_recurring_trigger!).with(other_donation, updatable_attributes).and_return(true)
        put :update, id: other_donation.id, :donation => { other_donation.id.to_s => updatable_attributes}

        response.should be_success
      end
    end
  end

  context "with logged in admin" do

    before :each do
      sign_in(create(:user, is_admin: true))
    end

    it "updates another's credit card and donation frequency details on recurring donation when logged in user is admin" do
      Donation.stub(find: donation)
      DonationService.any_instance.should_receive(:update_recurring_trigger!).with(donation, updatable_attributes).and_return(true)
      put :update, id: donation.id, :donation => { donation.id.to_s => updatable_attributes}

      response.should be_success
    end


  end

  context 'without logged in user' do
    describe 'update' do
      it "updates anonymously updatable attributes" do
        donation.stub(:can_update_anonymously?).and_return(true)

        Donation.stub(find: donation)
        DonationService.any_instance.should_receive(:update_recurring_trigger!).with(donation, anonymously_updatable_attributes).and_return(true)

        put :update, id: donation.id, :donation => { donation.id.to_s => updatable_attributes}

        response.should be_success
      end

      it "cannot update anonymously" do
        donation.stub(:can_update_anonymously?).and_return(false)

        Donation.stub(find: donation)
        DonationService.any_instance.should_not_receive(:update_recurring_trigger!)

        put :update, id: donation.id, :donation => { donation.id.to_s => updatable_attributes}

        response.should_not be_success
        response.body.should match /Permission denied/
      end
    end
  end

end
