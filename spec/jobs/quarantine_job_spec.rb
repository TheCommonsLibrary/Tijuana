require 'spec_helper'

QUARANTINE = UserActivityEvent::Activity::QUARANTINED

describe QuarantineJob do
  without_transactional_fixtures do
    let(:page) { create(:page_with_parent) }
    let(:list) { List.new }
    let(:job) { QuarantineJob.new(list, page) }
    let!(:u1) { create(:user, email: 'apple@pie.com') }
    let!(:u2) { create(:user, email: 'strawberry@pie.com') }
    let!(:u3) { create(:user, email: 'strawberry@other.com') }
    before do
      list.set_email_domain_rule(domain: '@pie.com')
      list.filter_by_rules
      job.perform
    end

    describe '#perform' do
      it "creates uae and quarantine records for existing users" do
        expect(is_quarantined(u1)).to eql true
        expect(is_quarantined(u2)).to eql true
        expect(is_quarantined(u3)).to eql false
      end

      context 'when called multiple times with the same user' do
        before { job.perform }

        it 'does not add duplicate user activity events' do
          expect(u1.user_activity_events.where(activity: QUARANTINE).count).to eql 1
        end
      end
    end
  end

  def is_quarantined(user)
    UserActivityEvent.find_by_user_id_and_activity(user.id, QUARANTINE) != nil &&
      !!Quarantine.find_by_user_id(user.id)
  end
end
