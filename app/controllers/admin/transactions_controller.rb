class Admin::TransactionsController < Admin::AdminController
  MAX_QUERY_RESULT_COUNT = 50000
  
  def index
    params[:filter] ||= {}
    filter = params[:filter]
    filter[:from_date] = default_from_date if filter[:from_date].blank?
    filter[:to_date] = default_to_date if filter[:to_date].blank?
    respond_to do |format|
      format.html { paginate_transactions }
      format.csv { download_csv }
    end
  end
  
  def show
    @transaction = Transaction.find(params[:id])
  end
  
  def refund
    @transaction = Transaction.find(params[:id])
    authorize! :refund, @transaction
    @transaction.refund!(params[:amount_in_dollars].to_f * 100)
    redirect_to admin_transaction_path(@transaction), :notice => "Transaction has been refunded"
  rescue Transaction::RefundFailedError => e
    flash[:error] = e.message
    render :action => "show"
  end
  
  
  private

  def default_from_date
    2.weeks.ago.strftime("%d-%m-%Y")
  end

  def default_to_date
    Time.zone.now.strftime("%d-%m-%Y")
  end

  def paginate_transactions
    relation = Transaction.filter_by(params[:filter])
    unless params[:query].blank?
      relation = merge_query_options(relation)
    end
    @transactions = Transaction.order('transactions.created_at DESC').page(params[:page])
    @transactions = @transactions.merge(relation).all
  end
  
  def download_csv
    authorize! :export, ExcelTransactionsReport

    relation = Transaction.filter_by(params[:filter])
    unless params[:query].blank?
      relation = merge_query_options(relation)
    end
    count = relation.count(:all)
    if params[:filter][:group_by].blank? && count > MAX_QUERY_RESULT_COUNT
      flash[:error] = "This query returns #{count} records. The maximum allowed is #{MAX_QUERY_RESULT_COUNT}. "
      redirect_to :action => "index"
    else
      report = get_report_class(params).send(:new, relation)
      Transaction.benchmark("Created CSV") do
        send_data(report.to_csv, :type => 'text/csv', :filename => "GetUp Transactions.csv")
      end
    end
  rescue ArgumentError
    flash[:error] = "Date format is invalid. Please use YYYY-MM-DD."
    redirect_to :action => "index"
  end

  def get_report_class(params)
    unless params[:filter].blank?
      params[:filter][:group_by].reject! { |e| e.blank? } unless params[:filter][:group_by].blank?
      params[:filter][:group_by].blank? ? ExcelTransactionsReport : ExcelGroupedTransactionsReport
    else
      ExcelTransactionsReport
    end
  end
  private :get_report_class

  def merge_query_options(relation)
    conditions = []
    unless params[:query].blank?
      q = params[:query]
      cents = q.gsub(/\$/, "").to_f * 100
      conditions << ["transactions.id = ? OR transactions.txn_ref = ? OR transactions.bank_ref = ? OR transactions.amount_in_cents = ?", q, q, q, cents]
      relation = relation.where(conditions.flatten)
    end
    relation
  end
  private :merge_query_options
end
