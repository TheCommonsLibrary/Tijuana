require 'spec_helper'

describe NationBuilder::SyncDonationFromTjToNbService do

  let!(:service){ NationBuilder::SyncDonationFromTjToNbService.new }
  let!(:nb_api){ NationBuilder::Api }

  describe "#sync!" do
    ['succesful', 'failed'].each do |status|
      context "with a #{status} transaction" do
        let!(:transaction){ create(:transaction, successful: status == 'successful' ) }
        let!(:nb_donation_fields){
          fields = {
            amount_in_cents: transaction.amount_in_cents,
            failed_at: (status == 'failed' ? transaction.updated_at : nil),
            donor_id: 5,
            ngp_id: transaction.id,
            payment_type_name: 'Credit Card',
          }
          fields[status == 'successful' ? :succeeded_at : :failed_at] = transaction.updated_at
          fields
        }
        it 'should call create a donation via the API' do
          nb_api.should_receive(:call_api).with(:donations, :create, donation: nb_donation_fields)
          service.sync! transaction
        end
      end
    end

    ['Offline donation #9263' => 'Check', 'Approved' => 'Credit Card']

    # handle paypal
    # Add custom fields and update transaction id, url in tijuana, and the message
    # if it was flagged
  end
end
