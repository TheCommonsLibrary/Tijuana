class MerchandiseReport
  attr_accessor :module_ids

  def initialize(*module_ids)
    self.module_ids = module_ids
  end


  def self.trigger_report(*module_ids)
    report = self.new(module_ids)
    MerchMailer.deliver_merchandise_email(report.to_csv, report.supplier_name)
    report.mark_as_reported
  end

  def merch_donations
    @merch_donations ||= (Donation
    .joins(:transactions, :user)
    .includes(:content_module, :transactions, :user => [:postcode])
    .where(content_module_id: @module_ids,transactions: {successful: true, refunded: false})
    .where('transactions.amount_in_cents > 0 AND donations.process_status is NULL'))
  end

  def item_mapping_key(donation)
    custom_field_names = donation.content_module.custom(:form_fields).map{|custom_field| custom_field[:name]}
    custom_field_names.map{|custom_field_name| donation.send(custom_field_name)}.join('')
  end

  def mark_as_reported
    merch_donations.all.each {|donation| donation.update_attribute(:process_status, 'REPORT_GENERATED')}
  end

  def supplier_name
    raise 'Must override and return the supplier name'
  end

  def to_csv
    raise 'Must override and generate a csv file'
  end
end