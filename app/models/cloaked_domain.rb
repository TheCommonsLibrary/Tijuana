class CloakedDomain
  def self.find(host)
    hash = AppConstants.cloaked_domains.constants_hash[host]
    hash ? CloakedDomain.new(hash) : nil
  end

  def initialize(hash)
    @hash = hash
    raise 'incorrectly configured cloaked domain in AppConstants' unless !!sequence ^ !!url
  end

  def sequence
    @hash['homepage_sequence']
  end

  def url
    @hash['homepage_url']
  end
end

class CloakedDomainConstraint
  def self.matches?(request)
    CloakedDomain.find(request.env["SERVER_NAME"])
  end
end