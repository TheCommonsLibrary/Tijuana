namespace :donations do

  desc 'Task to refund donations based associated with page IDs (pages ids and user ids must be separated by dashes)'
  task 'refund_by_page_ids', [:page_ids, :user_ids_to_exclude] => :environment  do |t, args|
    if !Rails.env.test?
      Rails.logger = Logger.new(STDOUT)
    end
    page_ids = (args[:page_ids].try(:split, '-') || []).map(&:to_i)
    user_ids_to_exclude = (args[:user_ids_to_exclude].try(:split, '-') || []).map(&:to_i)
    if page_ids.empty?
      Rails.logger.warn "Could not extract page ids from arguments: #{args}. Exiting."
      next
    end
    Rails.logger.info "Seaching for transactions on pages #{Page.find(page_ids).map{|p| "#{p.name}[#{p.id}]" }.to_sentence}"
    if user_ids_to_exclude.empty?
      Rails.logger.info "Not excluding any transactions by user ids"
    else
      Rails.logger.info "Excluding any transactions by user #{User.find(user_ids_to_exclude).map(&:email).to_sentence}"
    end
    transactions = Transaction.joins(:donation)
      .where(refunded: false)
      .where(successful: true)
      .where(Donation.arel_table['page_id'].in page_ids)
      .where(Donation.arel_table['payment_method'].eq('credit_card'))
      .where(Donation.arel_table['user_id'].not_in user_ids_to_exclude)
      .where(Transaction.arel_table[:amount_in_cents].gt(0))
    if transactions.empty?
      Rails.logger.warn "No transactions found! Exiting."
      next
    else
      Rails.logger.info "Found #{transactions.count} matching transactions. You now have 60s to consider this..."
    end
    sleep(60) unless Rails.env.test?
    total_refund = 0
    transactions.each do |transaction|
      transaction.refund!(transaction.amount_in_cents)
      total_refund += transaction.amount_in_cents
      Rails.logger.info "Refunded transaction #{transaction.id} for #{transaction.amount_in_cents}"
    end
    Rails.logger.info "Total refund is #{total_refund.to_f / 100} for transactions: #{transactions.map(&:id).join(',')}"
    Rails.logger.info "OK"
  end
end
