class MemberCountCalculator < ActiveRecord::Base
  FACTOR = 21 # take into account email bounces & avoid sudden spikes

  def self.set_count(val)
    first.update_attributes(:current => val)
  end
  
  def self.init
    unless first
      val = User.subscribed.count
      create(:current => val)
    end
  end

  def self.current
    first.current
  end

  def self.update!
    Rails.logger.debug {"MemberCountCalculator#update!: start"}
    member_count = first
    real_member_count = User.subscribed.count
    growth = (real_member_count - member_count.current)/FACTOR
    member_count.update_attributes!(:current => member_count.current + growth) if growth > 0
    current_count = member_count.current
    Rails.logger.debug {"MemberCountCalculator#update!: end"}
    current_count
  end
end
