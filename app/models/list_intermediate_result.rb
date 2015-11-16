class ListIntermediateResult < ActiveRecord::Base
  belongs_to :list
  serialize :data

end
