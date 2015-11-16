# "Petition Ask" module -- requests that user signs a petition
class PetitionModule < ContentModule
  include CustomFieldsForActions
  has_many :petition_signatures, :foreign_key => :content_module_id
  option_fields :signatures_target, :thermometer_threshold, :button_text, :petition_statement, :sign_with_facebook, :facebook_app_id
  
  after_initialize :defaults

  validates :signatures_target, :numericality => { :greater_than_or_equal_to => 0 }
  validates :thermometer_threshold, :numericality => { :greater_than_or_equal_to => 0 }
  validates :button_text, :length => { :minimum => 1, :maximum => 64 }
  validates :petition_statement, :length => { :minimum => 1 }

  def actions_on_page(page_id, limit=200)
    PetitionSignature.where(page_id: page_id).limit(limit)
  end

  def self.for_container?(layout_container)
    layout_container == :sidebar
  end

  def member_value_voice_module?
    true
  end

  def fb_app_id
    facebook_app_id.present? ? facebook_app_id : AppConstants.facebook_sign_petition_module_app_id
  end

  def display_sign_with_facebook?
    sign_with_facebook == '1'
  end

  def update_action_attributes_and_validate(params)
    petition_signature.attributes = params[:petition_signature].to_hash if params[:petition_signature]
  end
  
  def petition_signature
    @petition_signature ||= PetitionSignature.new( content_module: self )
  end

  def take_action(user, page, email=nil, params=nil, options={})
    unless custom_fields.try(:[],:allow_duplicates)
      raise DuplicateActionTakenError if PetitionSignature.where(:content_module_id => self, :user_id => user).count > 0
    end
    petition_signature.user = user
    petition_signature.page = page
    petition_signature.email = email
    if options[:source]
      petition_signature.source = options[:source]
    elsif display_sign_with_facebook?
      petition_signature.source = Vanity.ab_test(:sign_with_fb) == :experiment ? 'fb-exp' : 'fb-con'
    end
    create_action(petition_signature, options)
  end
  
  def signatures
    petition_signatures.count
  end
  
  def percentage_complete
    signatures_target.to_i == 0 ? 0 : signatures * 100 / signatures_target.to_i
  end

  def set_user_and_page(user, page)
    petition_signature.user = user
    petition_signature.page = page
  end
  
  private
  
  def defaults
    self.button_text = "Sign the petition!" unless self.button_text
    self.public_activity_stream_template = "{NAME|A member} added their signature to [a petition]." unless self.public_activity_stream_template
    self.sign_with_facebook = '1' if new_record?
  end
end
