require 'spec_helper'

describe TransactionsTable do
  describe "#rows" do
    context "with a donation on a deleted page" do
      let!(:deleted_page){ create(:page_with_parent) }
      let!(:donation){ create(:donation, page: deleted_page) }
      let!(:transaction){ create(:transaction, donation: donation) }
      before{ deleted_page.destroy! }

      it "should include the transaction with the page" do
        transaction.reload
        expect(TransactionsTable.new([transaction]).rows.first[11]).to eq(deleted_page.page_sequence.campaign.name)
      end
    end

    context "with a page with a deleted page sequence" do
      let!(:page){ create(:page_with_parent) }
      let!(:donation){ create(:donation, page: page) }
      let!(:transaction){ create(:transaction, donation: donation) }
      before{ page.page_sequence.destroy! }

      it "should include the transaction with the page" do
        transaction.reload
        expect(TransactionsTable.new([transaction]).rows.first[11]).to eq(page.page_sequence.campaign.name)
      end
    end
  end
end
