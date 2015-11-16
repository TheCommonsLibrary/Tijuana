desc 'add exclude quarantine to all lists'
task add_exclude_quarantine_to_lists: :environment do |t, args|
  List.all.each do |list|
    list.set_exclude_quarantine_rule
    list.save
  end
end
