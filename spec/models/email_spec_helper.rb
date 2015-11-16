def create_users_with_descending_randomicity(emails)
  random = 5
  users = emails.inject([]) do |acc, email|
    user = create(:user, :first_name => email.split('@')[0], :email => email, :country_iso => "AU", :postcode => create(:postcode, :number => random.to_s.rjust(4, "0")))
    user.random = random
    user.save!
    random -= 1
    acc << user
  end
  users
end

def tracking_hash_for(email, *users)
  users.inject([]) do |acc, user|
    acc << EmailTrackingToken.encode(user.id, email.id)
  end
end
