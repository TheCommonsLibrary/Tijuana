class AddIndexToVanityParticipants < ActiveRecord::Migration
  def change
    add_index :vanity_participants, :identity
  end
end
