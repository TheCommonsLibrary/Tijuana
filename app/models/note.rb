class Note < ActiveRecord::Base
  def self.create_or_update(value="")
    note = Note.first || Note.new
    note.value = value
    note.save ? note : nil
  end
end
