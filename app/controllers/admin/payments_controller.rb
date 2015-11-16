module Admin
  class PaymentsController < Admin::AdminController
    skip_authorize_resource # We have no static page model, which confuses CanCan.
    skip_authorization_check # Anyone with access to the admin interface can see the static pages index page.
  
    def show
      @blocked_ips ||= BlockedIp.all
      @gateway1_percentage ||= Setting.gateway1_percentage
    end
    
    def set_blocked_ips
      ips = params[:ip_addresses].strip.split(/[, \r\n]+/) unless params[:ip_addresses].blank?
      invalid_ip = nil
      begin
        BlockedIp.transaction do
          BlockedIp.delete_all
          unless ips.blank?
            ips.each do |ip|
              next if ip.blank?
              blocked_ip = BlockedIp.new(ip_address: ip)
              invalid_ip = ip unless blocked_ip.valid? 
              blocked_ip.save!
            end
          end
        end
        redirect_to admin_payments_path, :notice => 'IP addresses have been saved.'
      rescue ActiveRecord::RecordInvalid => invalid
        @blocked_ips = ips
        flash[:error] = "Changes not saved. '#{invalid_ip}': #{invalid.record.errors.full_messages[0]}" unless invalid_ip.nil?
        render_show_with_state
      end
    end

    def set_fraud_guard
      toggle_setting(params[:fraud_guard], :use_fraud_guard, 'FraudGuard')
    end

    def set_emergency_paypal
      toggle_setting(params[:emergency_paypal], :emergency_paypal, 'Emergency Paypal')
    end
    
    def set_gateway1_percentage
      @gateway1_percentage = params["gateway1_percentage"]
      if @gateway1_percentage.is_integer? && (0..100).include?(Integer @gateway1_percentage)
        Setting["gateway1_percentage"] = @gateway1_percentage
        redirect_to admin_payments_path, :notice => "#{GatewaySwitcher.gateway1_mapper.name} percentage has been saved"
      else
        flash[:error] = "#{GatewaySwitcher.gateway1_mapper.name} percentage is not a valid number between 0 and 100"
        render_show_with_state
      end
    end

    def toggle_setting(requested_setting, setting_key, feature_name)
      if !requested_setting.blank? && requested_setting.downcase == 'disabled'
        notice = 'disabled'
        Setting[setting_key] = nil
      else
        notice = 'enabled'
        Setting[setting_key] = 'true'
      end
      redirect_to admin_payments_path, :notice => "#{feature_name} has been #{notice}."
    end
    
  private
  
    def render_show_with_state
      show
      render :show
    end
  end
end
