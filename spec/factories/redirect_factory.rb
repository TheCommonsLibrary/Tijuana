FactoryGirl.define do
  factory(:redirect_path, :class => Redirect) do |r|
    r.alias_path    { "whats-happening" }
    r.target        { "http://getup.org.au" }
  end
  
  factory(:redirect_no_alias, :class => Redirect) do |r|
    r.target        { "http://getup.org.au" }
  end

end