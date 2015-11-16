require_relative '../recalculate_member_value_job'

namespace :member_value do

  desc 'Schedule a delayed jobs to recalculate the member value of all users. Delayed jobs run on batches of 1000 members.'
  task :recalculate_all_users => :environment do
    CHUNK_SIZE = 1000
    max_user_id = User.maximum(:id)
    min = 0
    max = CHUNK_SIZE

    while min < max_user_id
      Rails.logger.info "min: #{min}, max: #{max}, max_user_id: #{max_user_id}"
      Delayed::Job.enqueue RecalculateMemberValueJob.new(min, max)
      min = max
      max = max + CHUNK_SIZE
    end
  end
end