require 'rack/utils'

class Redirect < ActiveRecord::Base
  default_scope { order(:alias_path) }
  
  auto_strip_attributes :target
  
  validates :target, :length => { :minimum => 1, :maximum => 1024 }, :url => true

  validate :alias_path_or_alias_domain_present
  validate :t_param_not_present

  validates :alias_path, :length => { :minimum => 2, :maximum => 128 },
                    :uniqueness => { :message => "should be unique. There is an existing redirect on that path." },
                    :format => { :with => /\A[a-z0-9\-_!]*\z/, :message => "can only contain lowercase letters, numbers or hyphens."},
                    :if => 'alias_path.present?'

  validates :alias_domain, :length => { :minimum => 2, :maximum => 128 },
                    :uniqueness => { :message => "should be unique. There is an existing redirect on that domain." },
                    :format => { :with => /\A[a-z0-9\-\.]*\z/, :message => "can only contain lowercase letters, numbers, hyphens or full stops."},
                    :if => 'alias_domain.present?'
                    
  
  def alias_path_or_alias_domain_present
    self.errors.add(:alias_path, "or alias domain required.") if self.alias_path.blank? && self.alias_domain.blank?
    self.errors.add(:alias_path, "cannot be entered with alias domain.") if !self.alias_path.nil? && !self.alias_domain.nil?
  end
  
  def t_param_not_present
    self.errors.add(:target, "cannot contain t= parameter, it would override real tracking token") if target =~ /(\?|&)t=/
  end
  
  def name
    self.alias_path.blank? ? self.alias_domain : self.alias_path
  end

  def as_url(protocol, host)
    return "#{protocol}#{host}/#{self.name}" if self.alias_path?
    return "#{protocol}#{self.name}"
  end
  
  def self.merge_query_string(url, query)
    url_path, url_qs = url.split "?"
    combined_qs = Rack::Utils.parse_nested_query(query).merge Rack::Utils.parse_nested_query(url_qs)
    query.blank? ? url : "#{url_path}?#{Hash[combined_qs.sort].to_param}"
  end
end
