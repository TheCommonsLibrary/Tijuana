class TrackingTokenLookup
  def initialize(token)
    @token_hash = EmailTrackingToken.decode(token)
  end

  def valid?
    return if @token_hash.empty?
    email && user
  end

  def valid_source_token?
    @token_hash.any? && acquisition_source
  end

  def email
    @email ||= Email.where(:id => @token_hash[:emailid]).first unless @token_hash[:emailid].nil?
  end

  def user
    @user ||= User.where(:id => @token_hash[:userid]).first unless @token_hash[:userid].nil?
  end

  def acquisition_source
    @acquisition_source ||= AcquisitionSource.where(:id => @token_hash[:sourceid]).first unless @token_hash[:sourceid].nil?
  end
end
