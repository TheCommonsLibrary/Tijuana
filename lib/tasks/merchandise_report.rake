namespace :merch do
  namespace :occ do
    desc 'Send OCC merchandise report as an email'
    task :report => :environment do
      OccMerchandiseReport.trigger_report(5895, 5897, 5899)
    end
  end

  namespace :blackink do
    desc 'Send Black Ink merchandise report as an email to merch@getup.org.au. Use comma separated ids (max 5).'
    task :report, [*:a..:e] => [:environment] do |t, args|
      content_module_ids = args.values_at(*:a..:e).compact
      fail_with_no_args(t) if content_module_ids.nil?
      BlackInkMerchandiseReport.trigger_report(content_module_ids)
    end

    private

    def fail_with_no_args(task)
      raise "Could not complete #{task}. Please supply upto 5 MerchModule id's"
    end
  end

end
