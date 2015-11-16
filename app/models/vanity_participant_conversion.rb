class VanityParticipantConversion < ActiveRecord::Base
  attr_accessible :additional_id, :alternative, :experiment_id, :metric, :participant_id, :user_id, :value
end
