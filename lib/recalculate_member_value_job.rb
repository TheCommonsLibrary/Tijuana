class RecalculateMemberValueJob
  def initialize(min, max)
    @min = min
    @max = max
  end

  def perform
    with_logging(Logger::INFO) do
      users = User.where('id >= ?', @min).where('id < ?', @max)
      Rails.logger.info "User Count: #{users.count}"
      users.each do |user|
        MemberValue.recalculate_money_value(user)
        MemberValue.recalculate_time_value(user)
        MemberValue.recalculate_voice_value(user)
      end
    end
  end

  def with_logging(level)
    begin
      old_level = Rails.logger.level
      Rails.logger.level = level
      yield
    ensure
      Rails.logger.level = old_level
    end
  end
end