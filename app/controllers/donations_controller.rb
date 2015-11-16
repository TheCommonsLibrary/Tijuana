class DonationsController < ApplicationController
  include DashboardHelper
  
  def update
    donation = Donation.find(params[:id])
    raise "Permission denied" unless update_allowed?(donation)

    attrs = filter_updatable_attributes(params[:donation][donation.id.to_s])
    service = DonationService.new
    if service.update_recurring_trigger!(donation, attrs) # Takes a payment if no successful transactions present (eg. one_off)
      render :json => {status: "Ok", masked_card_number: mask_card_number(donation.card_number)}
    else
      render :json => donation.errors.to_json, :layout => false, :status => 500
    end

  rescue ActiveRecord::RecordInvalid
    render :json => donation.errors.to_json, :layout => false, :status => 500
  rescue Exception => e
    render :json => {"Credit Card" => " Unexpected Error. #{e.message}"}.to_json, :layout => false, :status => 500
  end

  private

  def filter_updatable_attributes(attrs)
    if current_user.present?
      attrs
    else
      attrs.except("frequency", "amount_in_dollars")
    end
  end

  def update_allowed?(donation)
    if donation.can_update_anonymously?
      true # allow user to update when not logged in
    else
      current_user.present? && ((donation.user.id == current_user.id) || current_user.is_admin?)
    end
  end

end
