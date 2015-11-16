class NationBuilder::SyncDonationFromTjToNbService

  def sync!(transaction)
    nb_donation = {
      amount_in_cents: transaction.amount_in_cents,
      donor_id: 5,
      ngp_id: transaction.id,
      payment_type_name: 'Credit Card',
    }
    nb_donation[transaction.successful? ? :succeeded_at : :failed_at] = transaction.updated_at
    NationBuilder::Api.call_api :donations, :create, donation: nb_donation
  end
end
