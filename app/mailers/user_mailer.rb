class UserMailer < GetupMailer

  def self.welcome_to_getup(user)
    if user.was_previously_unsubscribed?
      delay.welcome_back_to_getup_email(user)
    else
      delay.welcome_to_getup_email(user)
    end
  end

  def welcome_to_getup_email(user)
    @greeting = user.greeting || "there"
    mail(to: user.email, subject: "Thanks for joining the GetUp community!")
  end

  def welcome_back_to_getup_email(user)
    @greeting = user.greeting || "there"
    mail(to: user.email, subject: "Thanks for coming back to the GetUp community!")
  end

  def self.welcome_to_community_run(user)
    delay.welcome_to_community_run_email(user)
  end

  def welcome_to_community_run_email(user)
    @greeting = user.greeting || "there"
    mail(to: user.email, subject: "Welcome to CommunityRun")
  end

private

  def pre_process(body, recipient_name)
    replace_tokens(body,
                   "NAME" => recipient_name
    )
  end

end
