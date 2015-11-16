namespace :flag_donations do
  desc "unflag recurring donations that needs attention"
  task :unflag => :environment do
    Donation.active.flagged.update_all(["flagged_since = ?,flagged_because = ?", nil, nil])
  end

  #this is a one off task to rectify the issue where donations were flagged because
  #expiry dates were out of date but the donation was rectifed and has had a subsequent success
  desc "unflag flagged donations that are expired, but have subsequent successful transactions"
  task :correct_false_positives => :environment do
    sql = <<SQL
( (last_donated_at IS NOT NULL) 
  AND 
  ( 
    (card_expiry_month < MONTH(last_donated_at) AND card_expiry_year = YEAR(last_donated_at)) 
    OR card_expiry_year < YEAR(last_donated_at) 
  )
)
SQL
    Donation.active.flagged.where(sql).update_all(["flagged_since = ?, flagged_because = ?", nil, nil])
  end

  desc "set flagged_since and flagged_because to be nil for those flagged donation that have been dismissed"
  task :migrate_dismiss_column => :environment do
    Donation.where("dismissed_at IS NOT NULL").update_all(["flagged_since = ?, flagged_because = ?", nil, nil])
  end
end
