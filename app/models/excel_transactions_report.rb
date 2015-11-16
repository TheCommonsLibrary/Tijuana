require 'csv'

class ExcelTransactionsReport
  include ActionView::Helpers::NumberHelper

  def self.columns
    [
      "Donation ID", "Txn ID", "Member ID", "Member Email",
      "Txn Status", "Amount", "Txn Date", "Settlement Date", "Payment Method",
      "Cheque Number", "Cheque Name", "Cheque Bank", "Cheque Branch", "Cheque BSB", "Cheque Account Number",
      "Frequency", "Campaign", "Page Sequence", "Page"
    ]
  end

  def initialize(transactions)
    @transactions = transactions
  end
  
  def to_csv
    result = Transaction.connection.execute(@transactions.to_sql)
    name_to_index_map = array_to_index_lookup(result.fields)
    CSV.generate do |csv|
      csv << self.class.columns
      result.each do |txn|
        csv << row_for(ArrayAccessor.new(txn, name_to_index_map))
      end
    end
  end

  private

  def array_to_index_lookup(array)
    keys = {}
    array.each_with_index { |name, index| keys[name] = index }
    keys
  end

  def row_for(txn)

    payment_method = txn["payment_method"] == "credit_card" ? txn["card_type"] : txn["payment_method"]
    [
        txn["donation_id"],
        txn["txn_id"],
        txn["user_id"],
        txn["email"],

        txn["successful"] == 1 ? "Successful" : "Failed",
        faster_number_to_currency(txn["amount_in_cents"]),
        txn["created_at"].localtime,
        txn["settled_on"],
        faster_titlecase(payment_method || ""),

        txn["cheque_number"],
        txn["cheque_name"],
        txn["cheque_bank"],
        txn["cheque_branch"],
        txn["cheque_bsb"],
        txn["cheque_account_number"],

        faster_titlecase(txn["frequency"]),
        !txn["campaign_name"].blank? ? txn["campaign_name"] : "",
        !txn["page_sequence_name"].blank? ? txn["page_sequence_name"] : "",
        !txn["page_name"].blank? ? txn["page_name"] : "",
    ]
  end

  def faster_number_to_currency(arg)
    return '' if arg == nil
    sprintf('$%#.2f', arg/100.0)
  end

  def faster_titlecase(arg)
    arg.split('_').map(&:capitalize).join(' ')
  end

  class ArrayAccessor
    def initialize(array, map)
      @array = array
      @map = map
    end

    def [](name)
      @array[@map[name]]
    end
  end

end
