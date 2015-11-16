# 0,15,30,45 * * * * cd /var/www/getup/current && bundle exec rake low_volume_action_takers[PAGE_IDS_HERE]
desc 'Mark subscribers on a page as low volume. You can supply one or more page IDs(comma separated, no spaces). (e.g. rake low_volume_action_takers[2,3,24]'
task :low_volume_action_takers, [:page_id] => :environment do |task, args|
  ids = [args[:page_id]]
  ids.push(*args.extras) if args.extras
  UserActivityEvent.joins(:user).where(:page_id => ids).where("activity = 'subscribed'").where("users.low_volume = false").update_all(low_volume: true)
end
