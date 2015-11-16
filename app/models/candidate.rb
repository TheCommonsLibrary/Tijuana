class Candidate < ActiveRecord::Base
  belongs_to :electorate

  extend RemoveIdProtection
  include SerializeUnknownAttributes

  default_scope -> { order(:ballot_order) }

  before_create { self.electorate = Electorate.find_by_name(seat) }
end
