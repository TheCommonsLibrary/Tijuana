module StatsHelper
  def make_stats_data
    user = create(:user, :email => "email1@test.com")
    user1 = create(:user, :email => "email2@test.com")
    user2 = create(:user, :email => "email3@test.com")

    uae_user = UserActivityEvent.where(:user_id => user.id, :activity => "subscribed").last
    uae_user.created_at  = 1.week.ago + 1.day
    uae_user.save
    uae_user1 = UserActivityEvent.where(:user_id => user1.id, :activity => "subscribed").last
    uae_user1.created_at  = 2.years.ago
    uae_user1.save
    uae_user2 = UserActivityEvent.where(:user_id => user2.id, :activity => "subscribed").last
    uae_user2.created_at  = 1.year.ago + 1.day
    uae_user2.save

    donation_d = create(:donation, :amount_in_cents => 5000, :last_donated_at => 4.hours.ago, :created_at => 4.hours.ago, :user => user)
    donation_w = create(:donation, :amount_in_cents => 1000, :last_donated_at => 1.week.ago + 1.day, :created_at => 1.week.ago + 1.day, :user => user)
    donation_m = create(:donation, :amount_in_cents => 2000, :last_donated_at => 1.month.ago + 1.day, :created_at => 1.month.ago + 1.day, :user => user1)
    donation_y = create(:donation, :amount_in_cents => 3000, :last_donated_at => 1.year.ago + 1.day, :created_at => 1.year.ago + 1.day, :user => user2)
    donation_y1 = create(:donation, :amount_in_cents => 3000, :last_donated_at => 1.year.ago - 1.day, :created_at => 1.year.ago - 1.day, :user => user1)
    donation_y2 = create(:donation, :amount_in_cents => 3000, :last_donated_at => 2.years.ago, :created_at => 2.years.ago, :user => user1)

    transaction_d = create(:transaction, :amount_in_cents => 5000, :created_at => 4.hours.ago,  :updated_at => 4.hours.ago, :donation => donation_d)
    transaction_w = create(:transaction, :amount_in_cents => 1000, :created_at => 1.week.ago + 1.day, :updated_at => 1.week.ago + 1.day, :donation => donation_w)
    transaction_m = create(:transaction, :amount_in_cents => 2000, :created_at => 1.month.ago + 1.day, :updated_at => 1.month.ago + 1.day, :donation => donation_m)
    transaction_y = create(:transaction, :amount_in_cents => 3000, :created_at => 1.year.ago + 1.day, :updated_at => 1.year.ago + 1.day, :donation => donation_y)
    transaction_y1 = create(:transaction, :amount_in_cents => 3000, :created_at => 1.year.ago - 1.day, :updated_at => 1.year.ago - 1.day, :donation => donation_y1)
    transaction_y2 = create(:transaction, :amount_in_cents => 3000, :created_at => 2.years.ago, :updated_at => 2.years.ago, :donation => donation_y2)

    uae_d = UserActivityEvent.action_taken!(donation_d.user, donation_d.page, donation_d.content_module, transaction_d, donation_d.email)
    uae_w = UserActivityEvent.action_taken!(donation_w.user, donation_w.page, donation_w.content_module, transaction_w, donation_w.email)
    uae_m = UserActivityEvent.action_taken!(donation_m.user, donation_m.page, donation_m.content_module, transaction_m, donation_m.email)
    uae_y = UserActivityEvent.action_taken!(donation_y.user, donation_y.page, donation_y.content_module, transaction_y, donation_y.email)
    uae_y1 = UserActivityEvent.action_taken!(donation_y1.user, donation_y1.page, donation_y1.content_module, transaction_y1, donation_y1.email)
    uae_y2 = UserActivityEvent.action_taken!(donation_y2.user, donation_y2.page, donation_y2.content_module, transaction_y2, donation_y2.email)

    t_d_user = UserActivityEvent.where(:user_id => user.id, :activity => "action_taken", :user_response_id => transaction_d.id).last
    t_d_user.created_at  = 4.hours.ago
    t_d_user.save

    t_w_user = UserActivityEvent.where(:user_id => user.id, :activity => "action_taken", :user_response_id => transaction_w.id).last
    t_w_user.created_at  = 1.week.ago + 1.day
    t_w_user.save

    t_m_user = UserActivityEvent.where(:user_id => user1.id, :activity => "action_taken", :user_response_id => transaction_m.id).last
    t_m_user.created_at  = 1.month.ago + 1.day
    t_m_user.save

    t_y_user = UserActivityEvent.where(:user_id => user2.id, :activity => "action_taken", :user_response_id => transaction_y.id).last
    t_y_user.created_at  = 1.year.ago + 1.day
    t_y_user.save

    t_y1_user = UserActivityEvent.where(:user_id => user1.id, :activity => "action_taken", :user_response_id => transaction_y1.id).last
    t_y1_user.created_at  = 1.year.ago - 1.day
    t_y1_user.save

    t_y2_user = UserActivityEvent.where(:user_id => user1.id, :activity => "action_taken", :user_response_id => transaction_y2.id).last
    t_y2_user.created_at  = 2.years.ago
    t_y2_user.save
  end
end

RSpec.configuration.include StatsHelper