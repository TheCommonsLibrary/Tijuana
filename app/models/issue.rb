class Issue < ActiveRecord::Base
  belongs_to :electorate

  extend RemoveIdProtection
  include SerializeUnknownAttributes

  before_create { self.electorate = Electorate.find_by_name(seat) }

  def party_name(abbr)
    candidate = electorate.candidates.detect{|c| c[abbr.downcase].to_i == 1}
    if candidate.party_name == "Independent"
      "#{candidate.first_name} #{candidate.last_name}"
    else
      candidate.party_name
    end
  end
end
