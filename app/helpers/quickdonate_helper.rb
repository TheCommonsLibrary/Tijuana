module QuickdonateHelper

  def quickdonate_cookie?
    cookies.signed[:quick_donate_user_id].present?
  end

  def quickdonate_cookie_for?(user)
    cookies.signed[:quick_donate_user_id] == user.id if user.try(:id).present?
  end

  def enable_quickdonate_cookie_for(user)
    cookies.permanent.signed[:quick_donate_user_id] = {value: user.id, secure: use_secure_cookies?, httponly: true}
  end

  def remove_quickdonate_cookie
    cookies.delete(:quick_donate_user_id)
  end

  def display_quick_donate_enrol?(page)
    # WHEN: Quick donate is enabled on the module
    # AND (you're not enrolled to quick donate OR you don't have a session)
    # AND cc_logging is disabled
    Setting[:use_cc_logging].blank? && page.previous.try(:quick_donate_enabled?) &&
    (!enrolled_to_quick_donate? || !quickdonate_cookie_for?(just_donated_user)) &&
    (preceding_donation.present? && preceding_donation.by_credit_card?)
  end

  def quick_donate_card_info_if_quickdonate_cookie_for_user(user)
    quick_donate_card_info(user) if user.present? && quickdonate_cookie_for?(user)
  end

  def remove_action_id_from_session
    session.delete(:action_id) if session[:action_id].present?
  end

  private

  # Patched to false in scenario_helper as scenarios are on http
  def use_secure_cookies?
    !Rails.env.development?
  end

  def enrolled_to_quick_donate?
    just_donated_user.try(:quick_donate_trigger_id).present?
  end

  def just_donated_user
    preceding_donation.try(:user)
  end

  def preceding_donation
    @preceding_donation ||= Donation.find(session[:action_id]) if session[:action_id].present?
  end
end
