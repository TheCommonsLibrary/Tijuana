module UsersHelper

  def display_name(user_details_requirements, field, asterisk=true, field_display_name=nil)
    field_display_name = 'Home Phone' if field == :home_number
    placeholder = field_display_name || field.to_s.titlecase
    placeholder += "*" if asterisk && [:required, :refresh].include?(user_details_requirements.required_user_details[field])
    placeholder
  end

  def unsaved_user_value(field)
    @user.value_saved?(field) ? nil : @user.send(field)
  end

  def ask_for_user_field?(field)
    !@user.value_saved?(field)
  end

  def user_details_class(user_details_requirements, field, field_class=nil)
    elem_classes = []
    elem_classes << 'required' if [:required, :refresh].include?(user_details_requirements.required_user_details[field])
    elem_classes << field_class unless field_class.blank?
    elem_classes.join(' ')
  end

  def get_campaign_name_by_donation(donation)
    campaign = donation.page.page_sequence.campaign
    campaign_name = campaign.nil? ? "General" : campaign.name
    link_to(campaign_name,  edit_admin_page_path(donation.page))
  end

  def quick_donate_card_info(user)
    donation = user.find_quick_donation
    if (donation)
      "Donor: #{donation.name_on_card}<br>#{donation.card_type.blank? ? 'Credit Card' : donation.card_type.titleize}: " +
        "****#{donation.card_last_four_digits}, exp #{donation.card_expiry_month}/#{donation.card_expiry_year}"
    end
  end

end
