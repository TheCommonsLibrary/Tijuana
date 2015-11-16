class TellAFriendModule < ContentModule
  TWITTER_MAXIMUM = 107

  option_fields :email_body, :email_subject, :tweet_text, :html_meta_description

  after_initialize :defaults

  validates :email_subject, :length => { :minimum => 2, :maximum => 256 }
  validates :email_body, :length => { :minimum => 10 }
  validates :tweet_text, :length => { :minimum => 2, :maximum => TWITTER_MAXIMUM }
  validates :title, :length => { :maximum => 128, :minimum => 3 }
  
  def self.for_container?(layout_container)
    [:main_content, :aside_content].include? layout_container
  end

  private
  
  def defaults
    self.title = "Tell your friends!" unless self.title
    self.content = "Your friends would probably like to check this out, why don't you share it with them?" unless self.content
    self.email_subject = "Check out this GetUp! campaign" unless self.email_subject
    self.email_body = "Why don't you check out this?" unless self.email_body
    self.tweet_text = "Why don't you check out this?" unless self.tweet_text
  end
  
end
