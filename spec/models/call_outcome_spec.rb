require_relative "../spec_helper"

describe CallOutcome do
  let(:user) { FactoryGirl.create(:user) }
  let(:email) { user.email }

  context "without a user_id, tries to lookup by email" do
    let(:disposition) { "Dont Call Back EVER" }
    let!(:outcome) { FactoryGirl.create(:call_outcome, email: email, disposition: disposition) }

    it "sets the user's do_not_call attribute" do
      expect(user.reload.do_not_call).to eql(true)
    end
  end

  context "with a user_id" do
    let!(:outcome) { FactoryGirl.create(:call_outcome, user_id: user.id, disposition: disposition) }

    context "with a DNC outcome" do
      let(:disposition) { CallOutcome::DNC }
      it "sets the user's do_not_call attribute" do
        expect(user.reload.do_not_call).to eql(true)
      end
    end

    context "with a non-standard DNC outcome" do
      let(:disposition) { "Dont Call Back EVER" }
      it "sets the user's do_not_call attribute" do
        expect(user.reload.do_not_call).to eql(true)
      end
    end
  end
end
