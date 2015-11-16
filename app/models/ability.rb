class Ability
  include CanCan::Ability

  def initialize(user)    
      user ||= User.new
      if user.is_admin?
        can :manage, :all
      elsif user.is_volunteer?
        can :manage, :all
        cannot :change_roles, User
        cannot :destroy, [Campaign, PageSequence, Page, Push, Blast, Email, User, Merge]
        cannot :export, [AskStatsTable, EmailStatsTable, TransactionsTable, ExcelTransactionsReport, ExcelGroupedTransactionsReport]
        cannot :send, Blast
        cannot :refund, Transaction
      elsif user.is_member?
        can :manage, Event, new_record?: true,  get_together: { is_admin_managed: false }
        can :manage, Event, get_together: { is_admin_managed: false }, host: user
        can :email_attendees, Event, host: user
        cannot :update_host, Event, new_record?: false
      end
      can :index, Campaign # /admin routes to campaigns#index which redirects to the devise sign-in page.
  end
end
