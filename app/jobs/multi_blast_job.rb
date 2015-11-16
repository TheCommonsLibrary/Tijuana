class MultiBlastJob
  include InterruptableJob
  extend ActiveModel::Naming

  attr_reader   :errors
  attr_reader   :push
  attr_reader   :email_ids

  def initialize(options)
    @email_ids = options[:email_ids]
    @push = options[:push]
    @errors = ActiveModel::Errors.new(self)
  end

  def perform
    @email_ids.each {|email_id|
      email = Email.find(email_id)
      unless interrupted?
        blast_job = BlastJob.new(
          no_jobs: 1,
          current_job_id: 0,
          list: email.blast.list,
          email: email,
          limit: nil
        )
        blast_job.perform
      end
      email.blast.update_attribute(:delayed_job_id, nil)
    }
  end

  def valid?
    errors.clear
    emails = Email.where(id: @email_ids)
    validate_at_least_two
    validate_no_duplicates
    validate_all_emails_exist(emails)
    validate_one_email_per_blast(emails)
    validate_all_emails_have_correct_push(emails)
    validate_all_blasts_have_a_list(emails)
    validate_all_emails_have_been_proofed(emails)
    validate_push_not_in_progress
    errors.empty?
  end

  def self.load_job(delayed_job_id)
    job = Delayed::Job.where(id: delayed_job_id).first
    return nil if job.nil?
    handler = YAML.load(job.handler)
    return nil if handler.class != MultiBlastJob
    handler.before(job)
    handler
  end

  def contains_blast?(blast_id)
    emails = Email.where(id: @email_ids)
    emails.map(&:blast).map(&:id).include? blast_id
  end

  private

  def validate_no_duplicates
    duplicates = @email_ids.group_by {|id| id}.select { |k,v| v.size > 1}.keys
    duplicates.each { |id|
      errors.add(:email, "#{id} appears multiple times")
    }
  end

  def validate_one_email_per_blast(emails)
    emails.group_by(&:blast).each{ |blast, emails_in_blast|
      if emails_in_blast.length > 1
        errors.add(:emails, emails_in_blast.map{|e| "'#{e.name}'"}.join(' and ') + ' are in the same blast')
      end
    }
  end

  def validate_all_emails_have_correct_push(emails)
    emails.each { |email|
      unless email.blast.push == push
        errors.add(:email, "'#{email.id}' is not part of this push")
      end
    }
  end

  def validate_all_blasts_have_a_list(emails)
    emails.each { |email|
      unless email.blast.list.present?
        errors.add(:blast, "'#{email.blast.name}' requires a list in order to send")
      end
    }
  end

  def validate_all_emails_have_been_proofed(emails)
    emails.each { |email|
      unless email.proofed?
        errors.add(:email, "'#{email.name}' must be proofed")
      end
    }
  end

  def validate_push_not_in_progress
    unless push.blasts.map(&:delayed_job_id).compact.empty?
      errors.add(:push, 'is in progress')
    end
  end

  def validate_all_emails_exist(emails)
    existing_ids = emails.map(&:id)
    @email_ids.each{ |id|
      unless existing_ids.include?(id)
        errors.add(:email, "#{id} does not exist")
      end
    }
  end

  def validate_at_least_two
    unless @email_ids.length > 1
      errors.add(:multi_blast, "requires at least two ids")
    end
  end

end
