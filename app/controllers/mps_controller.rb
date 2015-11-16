class MpsController < ApplicationController

  before_filter :identify_module
  include MpActionHelper
  before_filter :cors

  def lookup
    @user_postcode = Postcode.find_by_number(params[:postcode].try(:strip))
    if @user_postcode
      targets = @mp_module.find_targeted_representatives(@user_postcode)
      @msg = @mp_module.target_message(@user_postcode)
      assign_target_variables(targets)
    else
      @msg = "Please enter a valid postcode."
    end
    respond_to do |format|
      format.html { render :layout => false }
      format.js { render :content_type => "text/html", :layout => false }
    end
  end

  def ensure_in_target_party
    mp = Mp.find(params[:mp_id])
    if @mp_module.targets_mp?(mp)
      assign_target_variables([mp])
      @msg = nil
    else
      @user_postcode = Postcode.find_by_number(params[:postcode].strip) if params[:postcode]
      if @user_postcode.nil?
        assign_target_variables([])
        @msg = "Postcode #{ERB::Util.html_escape(params[:postcode])} is not valid. Please try again."
      elsif @mp_module.target == 'MP or Senator'
        finder = TargetSenatorFinder.new(@mp_module.target_party_ids, @mp_module.jurisdiction_code)
        targets = finder.find_targeted_representatives(@user_postcode)
        assign_target_variables(targets)
        @msg = finder.target_message_when_falling_back(@user_postcode, targets, mp)
      else
        assign_target_variables([])
        @msg = "#{mp.full_name} does not represent one of the target parties of this campaign."
      end
    end
    respond_to do |format|
      format.html { render :layout => false }
      format.js { render :content_type => "text/html", :layout => false }
    end
  end

  def select_senator
    fallback_id = params[:fallback_id]
    senator = Senator.find_by_id(fallback_id)

    if @mp_module.targets_mp?(senator)
      @msg = evaluate_action_message(@mp_module, senator)
      @target = senator
    else
      @msg = "#{senator.full_name} does not represent one of the target parties of this campaign."
    end

    respond_to do |format|
      format.html { render :layout => false }
      format.js { render :content_type => "text/html", :layout => false }
    end
  end

  def party_options
    jurisdiction = Jurisdiction.find_by_code(params[:jurisdiction])
    @target_parties = jurisdiction.parties
    html = render_to_string :partial => 'admin/pages/content_modules/party_options', :formats => [:html]
    render :json => {:html => html, :target_senate => jurisdiction.upper_house_present?}.to_json
  end

  private

  def cors
    headers['Access-Control-Allow-Origin'] =  '*'
    headers['Access-Control-Request-Method'] = '*'
  end

  def identify_module
    if params[:module_id].nil?
      resource_not_found
    else
      @mp_module = ContentModule.where(:type => ["EmailMPModule", "CallMPModule"]).find(params[:module_id])
    end
  end

  def assign_target_variables(targets)
    if targets.length == 1
      @target = targets[0]
      @target_options = []
    else
      @target = nil
      @target_options = targets
    end
  end

end
