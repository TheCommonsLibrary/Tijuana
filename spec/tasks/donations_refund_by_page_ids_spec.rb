require 'spec_helper'
require 'rake'

describe "donations:refund_by_page_ids" do
  include_context "rake"

  its(:prerequisites) { should include("environment")  }

  context "with a transaction matching the page ids passed in the argument" do
    let!(:page){ create(:page_with_parent) }
    let!(:another_page){ create(:page_with_parent) }
    let!(:transaction){ create(:transaction, donation: create(:donation, page: page)) }
    let!(:paypal_transaction){ create(:transaction, donation: create(:donation, page: page, payment_method: 'paypal')) }

    it "should refund credit card transaction" do
      subject.invoke "#{page.id}-#{another_page.id}"
      transaction.reload
      transaction.should be_refunded
      paypal_transaction.reload
      paypal_transaction.should_not be_refunded
      refunds = transaction.donation.transactions(true).where(refund_of_id: transaction.id)
      refunds.count.should == 1
      refunds.first.amount_in_cents.should == -1 * transaction.amount_in_cents
    end

    context "with the user's id in the list of users to exclude" do

      it "should NOT refund that transaction" do
        subject.invoke "#{page.id}-#{another_page.id}", "#{transaction.donation.user_id}-#{create(:user).id}"
        transaction.reload
        transaction.should_not be_refunded
      end
    end
  end
end
