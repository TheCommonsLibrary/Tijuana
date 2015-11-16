class Homepage < ActiveRecord::Base
  include InlineTokenReplacement
  include ActionView::Helpers::NumberHelper
  validates :banner_text, :presence => true
  validates :campaign_image, :presence => true
  validates :campaign_url, :presence => true
  validates :campaign_alt_text, :presence => true
  validates :campaign2_image, :presence => true
  validates :campaign2_url, :presence => true
  validates :campaign2_alt_text, :presence => true
  validates :campaign3_image, :presence => true
  validates :campaign3_url, :presence => true
  validates :campaign3_alt_text, :presence => true
  acts_as_user_stampable
  
  def banner_html
    user_count = number_with_delimiter(MemberCountCalculator.current)
    replace_tokens(banner_text, "MEMBERCOUNT" => lambda { |default| "<span id=\"member-count\">#{user_count}</span>" })
  end
end
