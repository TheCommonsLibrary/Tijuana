require 'benchmark'

module Admin
  class ListCutterController < AdminController
    layout "admin"

    def new
      @list = List.new
      @list.blast = Blast.find(params[:blast_id]) if !params[:blast_id].blank?

      # default rules
      @list.set_exclude_low_volume_members_rule if AppConstants.low_volume_enabled
      @list.set_no_email_sent_today_rule(no_email_sent_today: true)
      @list.set_email_frequency_rule(email_frequency: 3, time_period: 6)
      @list.set_exclude_quarantine_rule
    end

    def edit
      @list = List.find(params[:list_id])
    end

    def count
      build_list_from_request

      intermediate_result_id = nil
      if @list.valid?
        @list.save
        @intermediate_result = ListIntermediateResult.create(:list => @list)
        @list.delay.count_stats_and_store_on(@intermediate_result)
        intermediate_result_id = @intermediate_result.id
      end
      render :json => {:intermediate_result_id => intermediate_result_id, :list_id => @list.id, :errors => @list.errors.messages}
    end

    def build_list_from_request
      @list = create_or_load_list
      active_rules = params[:rules].select { |rule_code, rule_params| rule_params[:activate] == "1" }
      active_rules.each do |rule_code, rule_params|
        rule_params[:not] = (rule_params[:not] == "true")
        rule_params.each { |key,values|
          values.delete_if{ |value| value.empty? } if ['states_territories' , 'frequencies', 'campaigns', 'electorate_ids', 'postcode_ids'].include? key
        }
        @list.send("set_#{rule_code}", rule_params.except(:activate))
      end
      @list.set_exclude_low_volume_members_rule if exclude_low_volume_members?(params)
      @list.set_exclude_quarantine_rule if exclude_quarantine_members?(params)
      @list
    end
    private :build_list_from_request

    def exclude_quarantine_members?(params)
      !params[:include_quarantine_members]
    end
    private :exclude_quarantine_members?

    def exclude_low_volume_members?(params)
      AppConstants.low_volume_enabled && !params[:include_low_volume_members]
    end
    private :exclude_low_volume_members?

    def create_or_load_list
      if params[:list_id].blank?
        list = List.new
        list.blast = Blast.find(params[:blast_id]) if !params[:blast_id].blank?
        list
      else
        list = List.find(params[:list_id])
        list.rules.clear
        list
      end
    end
    private :create_or_load_list

    def poll
      intermediate_result = ListIntermediateResult.find(params[:result_id])
      if intermediate_result && intermediate_result.ready?
        resp = {:ready => true}.merge(intermediate_result.data)
        render :json=> resp.to_json
      else
        resp = {:ready => false}
        render :json=> resp.to_json
      end
    end
  end
end
