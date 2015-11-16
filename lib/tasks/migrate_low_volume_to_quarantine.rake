namespace :migrate do
  desc 'Migrate all members on low volume to be quarantined'
  task low_volume_to_quarantine: :environment do
    UserActivityEvent.quarantines.find_each do |uae|
      user = uae.user
      user.create_quarantine
      user.update_attribute(:is_member, true)
    end
    User.where(low_volume: true).find_each do |user|
      user.update_attribute(:low_volume, false)
      user.quarantine!(source: 'migrate')
    end
  end
end
