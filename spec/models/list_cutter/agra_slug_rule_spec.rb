require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe ListCutter::AgraSlugRule do
  def ids(rule)
    rule.to_relation.map(&:id).uniq
  end

  describe "validation" do
    context "no slug specified" do
      specify {expect(subject.valid?).to be false }
    end
    context "slug specified" do
      let(:subject) { ListCutter::AgraSlugRule.new(slug: 'save-our-canterbury-hospital') }
      specify { expect(subject.valid?).to be true }
    end
  end

  describe "list cutting" do
    before do
      @canterbury_signer = create(:user)
      create(:agra_action_signer, user: @canterbury_signer, slug: 'save-our-canterbury-hospital')

      @rpa_signer = create(:user)
      create(:agra_action_signer, user: @rpa_signer, slug: 'save-our-royal-prince-alfred-hospital')

      @signed_both = create(:user)
      create(:agra_action_signer, user: @signed_both, slug: 'save-our-canterbury-hospital')
      create(:agra_action_signer, user: @signed_both, slug: 'save-our-royal-prince-alfred-hospital')

      @no_signature = create(:user)
    end

    context "with 'is' condition" do
      it "should return users who took action on associated CR campaign" do
        rule = ListCutter::AgraSlugRule.new(slug: 'save-our-canterbury-hospital')
        expect(ids(rule)).to match_array([@canterbury_signer.id, @signed_both.id])
      end

      context "multiple slugs" do
        it "should returns users who took action on any of the campaigns" do
          rule = ListCutter::AgraSlugRule.new(slug: ' save-our-canterbury-hospital, save-our-royal-prince-alfred-hospital ')
          expect(ids(rule)).to match_array([@canterbury_signer.id, @rpa_signer.id, @signed_both.id])
        end
      end
    end

    context "with 'is not' condition" do
      it "should return users who have not taken action on the campaign" do
        rule = ListCutter::AgraSlugRule.new(slug: 'save-our-canterbury-hospital', not: true)
        expect(ids(rule)).to match_array([@no_signature.id, @rpa_signer.id])
      end

      context "multiple slugs" do
        it "should return users who have not taken action on any of the specified campaigns" do
          rule = ListCutter::AgraSlugRule.new(slug: 'save-our-canterbury-hospital, save-our-royal-prince-alfred-hospital', not: true)
          expect(ids(rule)).to match_array([@no_signature.id])
        end
      end
    end
  end
end
