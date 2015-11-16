module ActsAsUserResponse
  def self.included(klass)
    klass.belongs_to :page, -> { with_deleted }
    klass.belongs_to :content_module
    klass.belongs_to :user
    klass.belongs_to :email
    klass.validates :page, :presence => true
    klass.validates :content_module, :presence => true
    klass.validates :user, :presence => true
  end
end
