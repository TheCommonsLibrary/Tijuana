require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe ListCutter::AgraRoleRule do

  def ids(rule)
    rule.to_relation.map(&:id).uniq
  end

  describe "validation" do
    context "without role" do
      specify { expect(subject.valid?).to be false }
    end

    context "with role" do
      let(:subject) { ListCutter::AgraRoleRule.new(role: 'creator') }
      specify { expect(subject.valid?).to be true }
    end
  end

  describe "list cutting" do
    before do
      @signer = create(:user)
      create(:agra_action_signer, user: @signer)

      @creator = create(:user)
      create(:agra_action_creator, user: @creator)

      @signer_and_creator = create(:user)
      create(:agra_action_signer, user: @signer_and_creator)
      create(:agra_action_creator, user: @signer_and_creator)
      
      @no_action = create(:user)
    end

    context "with 'is' condition" do
      it "should return users who match the role" do
        rule = ListCutter::AgraRoleRule.new(role: 'signer')
        expect(ids(rule)).to match_array([@signer.id, @signer_and_creator.id])

        rule = ListCutter::AgraRoleRule.new(role: 'creator')
        expect(ids(rule)).to match_array([@creator.id, @signer_and_creator.id])

        rule = ListCutter::AgraRoleRule.new(role: 'all')
        expect(ids(rule)).to match_array([@creator.id, @signer_and_creator.id, @signer.id])
      end
    end

    context "with 'is not' condition" do
      it "should exclude the specified role" do
        rule = ListCutter::AgraRoleRule.new(role: 'signer', not: true)
        expect(ids(rule)).to match_array([@creator.id, @no_action.id])

        rule = ListCutter::AgraRoleRule.new(role: 'creator', not: true)
        expect(ids(rule)).to match_array([@signer.id, @no_action.id])

        rule = ListCutter::AgraRoleRule.new(role: 'all', not: true)
        expect(ids(rule)).to match_array([@no_action.id])
      end
    end
  end
end
