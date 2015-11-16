[Devise::SessionsController, Devise::PasswordsController].each do |c|
  c.class_eval do
    def ssl_required?
      return true
    end
  end
end
