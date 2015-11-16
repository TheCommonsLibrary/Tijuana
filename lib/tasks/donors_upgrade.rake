namespace :donors do
  desc "Upgrade donations records and email donors based on CSV file passed in. E.g. rake donors:upgrade\[upgrades_140805.csv\]"
  task :upgrade, [:csv_file_name] => [:environment] do |t, args|
    # CSV format: u.email,old amount,oldfrequency,new amount,newfrequency
    require_relative('donor_upgrader')
    DonorUpgrader.new(args[:csv_file_name]).update_donations
  end
end
