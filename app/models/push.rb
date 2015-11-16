class Push < ActiveRecord::Base
  acts_as_paranoid
  acts_as_user_stampable
  belongs_to :campaign
  has_many :blasts

  validates :name, :length => { :maximum => 64, :minimum => 3 }

  after_commit :create_activities_table, :on => :create
  after_commit :drop_activities_table, :on => :destroy

  def create_activities_table
    raise RuntimeError if self.id.blank?
    create_table_sql = <<HERE
CREATE TABLE IF NOT EXISTS `push_#{self.id}` (
  `user_id` int(11) NOT NULL,
  `activity` varchar(64) NOT NULL,
  `email_id` int(11) NOT NULL,
  `created_at` DATETIME,
  KEY `activity_idx` (`activity`),
  KEY `email_idx` (`email_id`),
  KEY `user_idx` (`user_id`),
  KEY `user_activity_idx` (`user_id`,`activity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
HERE
    self.class.connection.execute(create_table_sql)
  end

  def drop_activities_table
    raise RuntimeError if self.id.blank?
    self.class.connection.execute("DROP TABLE IF EXISTS push_#{self.id}")
  end


#  This method resorts to raw SQL for performance reasons
#  Using ActiveRecord to create events for all sent emails clocked in 22 minutes for 450_000 users
#  This methods allowed the same amount of users to be inserted in 11 seconds
  def batch_create_sent_activity_event!(user_ids, email, batch_size=10_000)
    now = Time.now.utc
    insert_sql = "INSERT INTO push_#{self.id} (user_id, activity, email_id, created_at) VALUES "
    user_ids.each_slice(batch_size) do |slice|
      values = slice.inject([]) do |acc, user_id|
        acc << "(#{user_id}, 'email_sent', #{email.id}, :now)"
        acc
      end
      sql = insert_sql + values.join(',')
      execute_escaped sql, :now => now
    end
  end

  def count_by_activity(activity)
    sql = "select count(*) from push_#{self.id} where activity = ?"
    execute_escaped(sql, activity).to_a.flatten[0]
  end

  def self.log_activity!(activity, user, email)
    insert_sql = <<-HERE
      INSERT INTO push_? (user_id, activity, email_id, created_at)
      VALUES (?, ?, ?, ?);
    HERE
    execute_escaped insert_sql, email.blast.push.id, user.id, activity, email.id, Time.now.utc
  end

  def has_pending_jobs?
    self.blasts.map(&:has_pending_jobs?).inject(false){ |acc, val| acc = true if val == true; acc}
  end

  def acquire_lock
    return false if Push.currently_delivering
    Push.update_all(['locked_at = ?', Time.zone.now], ['id = ? AND locked_at IS NULL', id]) == 1
  end

  def release_lock
    update_attributes!(locked_at: nil)
  end

  def self.currently_delivering
    where('locked_at is not null').first
  end

  def multiblast_valid?(email_ids)
    multiblast_job = MultiBlastJob.new(email_ids: email_ids, push: self)
    unless multiblast_job.valid?
      multiblast_job.errors.each { |attribute, error|
        errors.add(attribute, error)
      }
    end
    errors.empty?
  end

  def send_multiblast!(email_ids)
    multiblast_job = MultiBlastJob.new(email_ids: email_ids, push: self)
    if multiblast_job.valid?
      job_handle = Delayed::Job.enqueue(multiblast_job, run_at: Time.now + AppConstants.blast_job_delay)
      emails = Email.find(email_ids, include: :blast)
      emails.each do |email|
        blasts.find{|blast| blast == email.blast}.update_attribute(:delayed_job_id, job_handle.id)
      end
    else
      raise "Can not send invalid multiblast: #{multiblast_job.errors.map{|attr, message| "#{attr}: #{message}"}.join(',')}"
    end
  end

  def cancel_multiblast!
    if blast_job_ids.present?
      multiblast_job_id = blast_job_ids.first
      cancel_status = InterruptableJob.cancel(multiblast_job_id)
      if cancel_status == InterruptableJob::CANCEL_STATUS[:destroyed]
        Blast.update_all('delayed_job_id = NULL', "push_id = #{id} AND delayed_job_id = #{multiblast_job_id}")
      end
      cancel_status
    end
  end

  def cancelling_multiblast?
    InterruptableJob.interrupted?(blast_job_ids.first)
  end

  def sending_multiblast?
    load_multiblast.present?
  end

  def multiblast_emails
    Email.find(load_multiblast.email_ids)
  end

  def multiblast_contains_blast?(blast_id)
    multiblast_job = MultiBlastJob.load_job(blast_job_ids.first)
    multiblast_job.present? ? multiblast_job.contains_blast?(blast_id) : false
  end

  def has_been_sent?
    !!self.blasts.collect(&:emails).flatten.detect {|e| e.has_been_sent? }
  end

  def duplicate
    new_push = dup
    new_push.name = "#{name} [clone #{Time.now.to_s(:short)}]"
    blasts.each do |blast|
      new_blast = blast.dup
      new_blast.sent_at = nil
      new_blast.save!
      new_blast.list = blast.list.dup if blast.list.present?
      blast.emails.each do |email|
        next if email.name.include?(Email.new.send(:subject_line_prefix))
        new_email = email.dup
        new_blast.emails << new_email
      end
      new_push.blasts << new_blast
    end
    new_push.save!
    new_push
  end

  private

  def load_multiblast
    MultiBlastJob.load_job(blast_job_ids.first)
  end

  def blast_job_ids
    blasts.map(&:delayed_job_id).compact.uniq
  end
end
