require 'spec_helper'
require 'rake'

describe 'email_mp_resend' do
  include_context 'rake'

  its(:prerequisites) { should include('environment')  }

  context 'with emails incorrectly sent to Senator Wong', delay_jobs: false do
    let!(:pup_party){ create(:party, abbreviation: 'PUP')  }
    let!(:labor_party){ create(:party, abbreviation: 'ALP')  }
    let!(:incorrect_senator){ 'senator.wong@aph.gov.au' }
    let!(:correct_senator){ 'senator.wang@aph.gov.au' }
    let!(:email_mp_module){ create(:email_mp_module, target_party_ids: { pup_party.id => '1' })  }
    let!(:user_email){ create(:user_email, content_module: email_mp_module, targets: incorrect_senator) }
    let!(:user_email_that_was_cced){ create(:user_email, content_module: email_mp_module, targets: incorrect_senator, cc_me: true) }
    before{ ActionMailer::Base.deliveries.clear }
    
    it 'should update the delayed_end_date on the content_modules to be in the future' do
      Timecop.freeze do
        subject.invoke
        email_mp_module.reload
        email_mp_module.delayed_end_date.should == 4.days.since
      end
    end

    describe 'the emails resent by the task' do
      before{ subject.invoke }
      
      it 'should update the record to the correct senator' do
        UserEmail.where(targets: correct_senator).count.should == 2
      end

      it 'should schedule them to be resent to the correct senator' do
        ActionMailer::Base.deliveries.select{|d| d.to.include? correct_senator }.count.should == 2
      end

      it 'should unset the cc_me so they are not emailed again' do
        ActionMailer::Base.deliveries.select{|d| d.to.any? { |s| s =~ /person[0-9]@example.com/ } }.count.should == 0
      end
    end
  end
end
