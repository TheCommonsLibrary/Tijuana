desc "This task is called by the Heroku cron add-on"
task :cron => :environment do
  begin
    Rails.logger.formatter = Logger::Formatter.new
    Rails.logger.debug {"CRON_DEBUG: start"}
    
    donation_service = DonationService.new
    # third parameter of trigger_due_periodic_payments! should correspond to the period that this task runs
    now = Time.now
    donation_service.trigger_due_periodic_payments! "weekly", now - (24*7).hours, 1.hour # (24*7).hours = 1 week regardless of daylight savings
    donation_service.trigger_due_periodic_payments! "monthly", now - 1.month, 1.hour
    donation_service.trigger_due_periodic_payments! "annual", now - 1.year, 1.hour

    donation_service.clear_all_out_of_date_one_off_with_triggers(1.month.ago)

    User.update_random_values if Time.zone.now.hour == 3 #3am

    DonationTriggerService.new.delay.fire_trigger if Time.zone.now.hour == 4 #4am

    MemberCountCalculator.update! if Time.zone.now.hour == 2
    Stats::TransparencyStats.new.delay.update if Time.zone.now.hour == 2

    TagMiddleDonorsService.delay.tag! if Time.zone.now.hour == 3
    #MerchandiseReport.trigger_report(5895, 5897, 5899) if Time.zone.now.hour == 9
  rescue => e
    ExceptionNotifier.notify_exception(e).deliver
    raise e
  ensure
    Rails.logger.debug {"CRON_DEBUG: end"}
  end
end
