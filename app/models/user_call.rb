class UserCall < ActiveRecord::Base
  include ActsAsUserResponse
  include CustomFieldsFromContentModule
  
  belongs_to :call_mp_module, :foreign_key => 'content_module_id', :class_name => 'CallMPModule'

  validates :targets, :presence => { :message => '^Please select the MP or Senator that you called.' }, :unless => 'call_mp_module.arbitrary_target?'
  validates :start_time, :presence => { :message => '^Please select a time to call' }, :if => 'call_mp_module.schedule_calls'
end
