namespace :donations do
  desc "Update donations records and email donors based on CSV file passed in. E.g. rake donations:update[upgrades_140805.csv]"
  task :update, [:csv_file_name] => [:environment] do |t, args|
    require_relative('donation_updater')
    DonationUpdater.new(args[:csv_file_name]).update_donations
  end
end
