class Admin::DonationsController < Admin::AdminController
  OFFLINE_ATTRIBUTES = {:frequency => "one_off"}
  OFFLINE_PAYMENT_METHOD = ["cheque", "eftpos", "cash", "money_order", "bank_cheque"]

  def new
    @donation = Donation.new((params[:donation] || {}).merge(:page_id => nil))
    @transaction = Transaction.new(:created_at => Time.zone.now)
  end

  def create
    offline_donations_page = offline_donation_page(params[:campaign])
    @donation = Donation.new((params[:donation] || {}).merge(OFFLINE_ATTRIBUTES).merge(last_donated_at: Time.zone.now, page: offline_donations_page))
    lookup_donation_module
    @donation.valid?
    validate_offline_transaction if OFFLINE_PAYMENT_METHOD.include? @donation.payment_method
    if @donation.errors.empty? and @transaction.errors.empty?
      @donation.save
      create_transaction_for_offline_donation
      ContentModule.create_uae_and_shared_connection(@donation, @donation.transactions.first, nil, nil)
      send_offline_receipt_email @donation
      redirect_to admin_transactions_path, :notice => "Offline donation has been created."
    else
      flash[:error] = "Your changes have NOT BEEN SAVED YET. Please fix the errors below."
      render :action => "new"
    end
  end

  def offline_donation_page(campaign_id)
    if campaign_id.present?
      Campaign.find(campaign_id).find_or_create_offline_donation_page
    else
      PageSequence.find_global_donations_page_sequence.pages.first
    end
  end

  def edit
    @donation = Donation.find(params[:id])
    render :action => "edit"
  end

  def update
    @donation = Donation.find(params[:id])
    if OFFLINE_PAYMENT_METHOD.include? @donation.payment_method
      @transaction = @donation.transactions.first
      update_offline_donation
    elsif @donation.frequency == "one_off"
      update_oneoff_donation
    else
      update_donation
    end
  end

  def update_offline_donation
    offline_donations_page = offline_donation_page(params[:campaign])
    @donation.attributes = params[:donation].merge(:page => offline_donations_page)
    @donation.valid?
    @transaction.attributes = params[:transaction]
    @transaction.valid?
    if @donation.errors.empty? and @transaction.errors.empty?
      @donation.update_attributes(params[:donation])
      @transaction.update_attributes(:amount_in_cents => params[:donation][:amount_in_dollars].to_f * 100, :created_at => params[:transaction][:created_at])
      redirect_to admin_transactions_path, :notice => "Donation has been updated."
    else
      flash[:error] = "The donation has not been updated. Please fix the errors below."
      render :action => "edit_offline_donation"
    end
  end

  private :update_offline_donation

  def update_oneoff_donation
    @user = User.find(@donation.user_id)
    if @donation.update_attributes(params[:donation])
      redirect_to admin_transactions_path, :notice => "Donation has been updated."
    else
      flash[:error] = "The donation has not been updated. Please fix the errors below."
      render :action => "edit_oneoff_donation"
    end
  end

  private :update_oneoff_donation

  def update_credit_card_identifiers
    @donation = Donation.find(params[:id])
    attributes_to_update = params[:donation].slice(
        :frequency,
        :amount_in_dollars,
        :card_last_four_digits,
        :card_expiry_month,
        :card_expiry_year)
    @donation.attributes = attributes_to_update
    @donation.validate_credit_card_indentifiers
    if @donation.errors.count == 0
      columns_to_update = attributes_to_update.merge({'amount_in_cents' => @donation.amount_in_cents}).delete_if{|k, v| k == 'amount_in_dollars'}
      Donation.where(id: @donation.id).update_all(columns_to_update)
      redirect_to edit_admin_user_path(@donation.user), :notice => "Donation has been updated."
    else
      flash[:error] = "The donation has not been updated. Please fix the errors below."
      render :action => 'edit'
    end
  end

  def update_donation
    if @donation.update_attributes(params[:donation])
      redirect_to edit_admin_user_path(@donation.user), :notice => "Donation has been updated."
    else
      flash[:error] = "The donation has not been updated. Please fix the errors below."
      render :action => "edit"
    end
  end

  private :update_donation

  def edit_offline_donation
    @donation = Donation.find(params[:id])
    @transaction = @donation.transactions.first
  end

  def edit_oneoff_donation
    @donation = Donation.find(params[:id])
    raise "update oneoff donation won't available after a month" unless @donation.less_than_one_month
    @user = User.find(@donation.user_id)
  end

  def cancel_recurring
    @donation = Donation.find(params[:id])
    @donation.cancel_recurring!(params[:donation][:cancel_reason])
    CancelledRecurringDonationEmail.new(@donation).send!

    if params[:redirect_to]
      redirect_to params[:redirect_to], :notice => "Recurring donation has been cancelled."
    else
      redirect_to edit_admin_user_path(@donation.user), :notice => "Recurring donation has been cancelled."
    end
  end

  def assign_flagged_donation
    @donation = Donation.find(params[:id])
    Donation.where(:id => params[:id]).update_all(["assigned_to = ?, assigned_date =? ", current_user.full_name, Time.now])
    redirect_to edit_admin_user_path(@donation.user)
  end

  def flagged
    if params[:selected] == '0'
      @flagged_donations = Donation.order('donations.flagged_since DESC').flagged_recurring_donations(params[:search]).page(params[:page])
      @failed_new_donations = Donation.flagged_new_donations(params[:search]).page(1)
    else
      @flagged_donations = Donation.flagged_recurring_donations(params[:search]).page(1)
      @failed_new_donations = Donation.order('donations.flagged_since DESC').flagged_new_donations(params[:search]).order('donations.flagged_since DESC').page(params[:page])
    end
  end

  def dismiss(selected_tab)
    if !params[:donations].nil?
      ids = params[:donations].map(&:first)

      if Donation.where(:id => ids).update_all(["dismissed_at = ?", Time.now]) > 0
        redirect_to flagged_admin_donations_path(:selected => selected_tab, :page => params[:page]), :notice => "The selected donations have been dismissed."
      else
        redirect_to flagged_admin_donations_path(:selected => selected_tab, :page => params[:page]), :flash => {:error => "No donations were dismissed."}
      end
    else
      redirect_to flagged_admin_donations_path, :flash => {:warning => "No donations have been selected." }
    end
  end

  def dismiss_recurring_donations
    dismiss(0)
  end

  def dismiss_failed_new_donations
    dismiss(1)
  end


  private

  def lookup_donation_module
    @donation.page ||= StaticPage.global_donation
    if page = @donation.page
      @donation.content_module = page.ask_module
    end
  end

  def validate_offline_transaction
    @transaction = Transaction.new((params[:transaction] || {}).merge(:message => "Offline donation ##{@donation.id}"))
    @transaction.valid?
  end

  def create_transaction_for_offline_donation
    @donation.transactions.create!(
        :amount_in_cents => @donation.amount_in_cents,
        :created_at => @transaction.created_at,
        :bank_ref => nil,
        :message => "Offline donation ##{@donation.id}",
        :response_code => nil,
        :successful => true
    )
  end

  def send_offline_receipt_email donation
    OfflineDonationReceiptEmail.new(donation.transactions).send!
  end
end
