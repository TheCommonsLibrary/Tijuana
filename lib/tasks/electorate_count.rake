desc "Some task"
task :electorate_count => :environment do

  CSV.open("tmp/electorates.csv", "wb") do |csv|
    r = Electorate.where(jurisdiction_id: 9).map do |e|
      users_in_postcode = e.postcodes.map do |p|
        users = User.where(postcode_id: p.id, is_member: true).where("users.deleted_at is null").count
        electorates = Electorate.count_by_sql("SELECT COUNT(*) FROM electorates_postcodes INNER JOIN electorates ON electorates.id = electorates_postcodes.electorate_id WHERE postcode_id = #{p.id} AND electorates.jurisdiction_id = 9")
        { postcode: p.number, number_users: users.to_f, number_electorates: electorates.to_f }
      end

      user_count_for_electorate = users_in_postcode.inject(0) do |sum, u| 
        sum + (u[:number_users] / u[:number_electorates]) 
      end

      csv << [e.id, e.name, user_count_for_electorate] if user_count_for_electorate.to_f != 0.0
    end
  end
end