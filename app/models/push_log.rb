class PushLog < ActiveRecord::Base
  def self.log_exception(email, user_ids, exception)
    msg = "Push: #{email.blast.push.id} - Blast: #{email.blast.id} - Email: #{email.id} - User ids: #{[user_ids].flatten.join(",")} - Exception: #{exception.message}"
    PushLog.create!(:message => msg)
  end
end
