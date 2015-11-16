class TellAFriendAskModule < ContentModule
  option_fields :email_body, :email_subject, :tweet_text, :html_meta_description

  after_initialize :defaults

  validates :email_subject, :length => { :minimum => 2, :maximum => 256 }
  validates :email_body, :length => { :minimum => 10 }
  validates :tweet_text, :length => { :minimum => 2, :maximum => TellAFriendModule::TWITTER_MAXIMUM }
  validates :title, :length => { :maximum => 128, :minimum => 3 }
  
  def self.for_container?(layout_container)
    layout_container == :sidebar
  end
  
  def take_action
    return true
  end

  private
  
  def defaults
    self.title = "Tell your friends!" unless self.title
    self.content = "Your friends would probably like to check this out, why don't you share it with them?" unless self.content
    self.email_subject = "Check out this GetUp! campaign" unless self.email_subject
    self.email_body = "Why don't you check out this?" unless self.email_body
    self.tweet_text = "Why don't you check out this?" unless self.tweet_text
    self.public_activity_stream_template = "Why don't you check out this?" unless self.public_activity_stream_template
  end
  
end
