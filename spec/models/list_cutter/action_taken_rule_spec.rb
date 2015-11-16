require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe ListCutter::ActionTakenRule do
  describe '#to_relation' do
    before do
      @page_1 = create(:page_with_parent)
      @page_2 = create(:page_with_parent)
      @page_3 = create(:page_with_parent)

      @petition_module = create(:petition_module, :public_activity_stream_template => "Someone signed!")
      @email = create(:email)
      
      @user_a = create(:user)
      @signature_a = create(:petition_signature, :user => @user_a, :content_module => @petition_module)
      UserActivityEvent.action_taken!(@user_a, @page_1, @petition_module, @signature_a, @email)
      UserActivityEvent.action_taken!(@user_a, @page_2, @petition_module, @signature_a, @email)
      UserActivityEvent.action_taken!(@user_a, @page_3, @petition_module, @signature_a, @email)

      @user_b = create(:user)
      @signature_b = create(:petition_signature, :user => @user_b, :content_module => @petition_module)
      UserActivityEvent.action_taken!(@user_b, @page_1, @petition_module, @signature_b, @email)
      UserActivityEvent.action_taken!(@user_b, @page_3, @petition_module, @signature_b, @email)   

      @user_c = create(:user)
      @signature_c = create(:petition_signature, :user => @user_c, :content_module => @petition_module)
      UserActivityEvent.action_taken!(@user_c, @page_3, @petition_module, @signature_c, @email)

      @user_d = create(:user)

    end

    context "when not negated" do
      context 'when actions taken is greater than 0' do
        it 'returns the right users' do
          rule = ListCutter::ActionTakenRule.new(page_ids: "#{@page_1.id}, #{@page_3.id}", greater_than: 0)
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.uniq.size.should eql 3
          user_ids.should include(@user_a.id, @user_b.id, @user_c.id)
        end
      end

      context 'when actions taken is greater than 1' do
        it 'returns the right users' do
          rule = ListCutter::ActionTakenRule.new(page_ids: "#{@page_1.id}, #{@page_3.id}", greater_than: 1)
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.size.should eql 2
          user_ids.should include(@user_a.id, @user_b.id)
        end
      end

      context 'when actions taken is greater than 2' do
        it 'returns the right users' do
          rule = ListCutter::ActionTakenRule.new(page_ids: "#{@page_1.id}, #{@page_3.id}", greater_than: 2)
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.should be_empty
        end
      end
    end
    context "when negated" do
      context 'when actions taken is less than or equal to 0' do
        it 'returns the right users' do
          rule = ListCutter::ActionTakenRule.new(not: true, page_ids: "#{@page_1.id}, #{@page_3.id}", greater_than: 0)
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.uniq.size.should eql 1
          user_ids.should include(@user_d.id)
        end
      end

      context 'when actions taken is less than or equal to 1' do
        it 'returns the right users' do
          rule = ListCutter::ActionTakenRule.new(not: true, page_ids: "#{@page_1.id}, #{@page_3.id}", greater_than: 1)
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.size.should eql 2
          user_ids.should include(@user_c.id, @user_d.id)
        end
      end

      context 'when actions taken is less than or equal to 2' do
        it 'returns the right users' do
          rule = ListCutter::ActionTakenRule.new(not: true, page_ids: "#{@page_1.id}, #{@page_3.id}", greater_than: 2)
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.size.should eql 4
          user_ids.should include(@user_a.id, @user_b.id, @user_c.id, @user_d.id)
        end
      end
    end
  end
  
  describe "validation" do
    it "should ensure page ids present" do
      rule = ListCutter::ActionTakenRule.new
      rule.should have(1).errors_on(:page_ids)
    end

    it "should ensure page ids numberic" do
      rule = ListCutter::ActionTakenRule.new(:page_ids=>'asfsadf')
      rule.should have(1).errors_on(:page_ids)
    end

    it "should catch invalid page ids" do
      page = create(:page_with_parent)
      rule = ListCutter::ActionTakenRule.new(:page_ids => "999998, #{page.id}, 999999")
      rule.valid?.should be false
      rule.errors.messages.should == {:page_ids=>["invalid page id(s) 999998, 999999"]}
    end

    it "should accept valid page ids" do
      page = create(:page_with_parent)
      rule = ListCutter::ActionTakenRule.new(:page_ids => "#{page.id}")
      rule.valid?.should be true
    end
  end
end
