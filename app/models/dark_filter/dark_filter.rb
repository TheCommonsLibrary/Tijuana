module DarkFilter
  class DarkFilter < ActiveRecord::Base

    validates_presence_of :name
    has_many :experiments, class_name: 'DarkFilter::Experiment' 

    # Add the member to experiment group unless they're part of another experiment
    def add_member_to_experiment(member, subscription_data={})
      if recruiting_and_member_not_in_experiment?(member)
        experiments.create!(user: member, control: false)
      end
    end

    # Add the member to control group unless they're part of another experiment
    def add_member_to_control(member, subscription_data={})
      if recruiting_and_member_not_in_experiment?(member)
        experiments.create!(user: member, control: true)
      end
    end

    # Consider this member for an experiment for an active dark filter. All
    # members get assigned randomly to one of the available experiments
    # - either in the control or in the experiment group
    # Fitlers are either for AGRA members or not
    def self.consider_for_experiment(member, subscription_data={})
      from_community_run = subscription_data[:source] == 'cr'
      filters = where(recruiting: true).order(:created_at)
        .select{|filter| from_community_run == filter.agra_only? }
      return if filters.empty?
      in_control_group = [true, false].sample
      selected_filter = filters.sample
      if in_control_group
        selected_filter.add_member_to_control(member, subscription_data)
      else
        selected_filter.add_member_to_experiment(member, subscription_data)
      end
    end

    # Filter is only for agra members if true
    def agra_only?
      false
    end

    protected

    def recruiting_and_member_not_in_experiment?(member)
      recruiting? && !Experiment.where(user_id: member.id).exists?
    end
  end
end
