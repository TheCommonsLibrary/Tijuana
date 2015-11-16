shared_examples_for "a target representative finder" do

  before :each do
    @representative_finding_module = create(described_class.to_s.underscore.to_sym)
  end

  it "defaults to finding MPs if target not set (legacy admin)" do
    @representative_finding_module.target.should == 'MP'
  end

  it "defaults finds MPs with fallback to Senators if target not set but target_senate set (legacy admin)" do
    @representative_finding_module.target_senate = '1'
    @representative_finding_module.target.should == 'MP or Senator'
  end

  it "accepts setting for target" do
    @representative_finding_module.target = 'Boo'
    @representative_finding_module.target.should == 'Boo'
  end


  context 'with party ids and jurisdiction code' do
    let :postcode do build(:postcode) end

    before :each do
      @representative_finding_module.jurisdiction_code = 'JR1'
      @representative_finding_module.target_party_ids = {'1' => '1', '2' => '1'}
      @mock_finder = double("Finder")
      @mock_result = double("Result", shuffle: 'shuffed results')
    end

    describe 'find_targeted_representatives' do

      it "uses TargetMpFinder to find shuffled MPs" do
        @representative_finding_module.target = 'MP'
        TargetMpFinder.should_receive(:new).with([1, 2], 'JR1', false).and_return(@mock_finder)
        @mock_finder.should_receive(:find_targeted_representatives).with(postcode).and_return(@mock_result)
        @representative_finding_module.find_targeted_representatives(postcode).should == 'shuff'
      end

      it "uses TargetMpFinder to find shuffled MPs with fallback" do
        @representative_finding_module.target = 'MP or Senator'
        TargetMpFinder.should_receive(:new).with([1, 2], 'JR1', true).and_return(@mock_finder)
        @mock_finder.should_receive(:find_targeted_representatives).with(postcode).and_return(@mock_result)
        @representative_finding_module.find_targeted_representatives(postcode).should == 'shuff'
      end

      it "uses TargetSenatorFinder to find shuffled Senators" do
        @representative_finding_module.target = 'Senator'
        TargetSenatorFinder.should_receive(:new).with([1, 2], 'JR1').and_return(@mock_finder)
        @mock_finder.should_receive(:find_targeted_representatives).with(postcode).and_return(@mock_result)
        @representative_finding_module.find_targeted_representatives(postcode).should == 'shuff'
      end

    end

    describe 'target_message' do

      it "uses TargetMpFinder to find target_message" do
        @representative_finding_module.target = 'MP'
        TargetMpFinder.should_receive(:new).with([1, 2], 'JR1', false).and_return(@mock_finder)
        @mock_finder.should_receive(:target_message).with(postcode).and_return("return value")
        @representative_finding_module.target_message(postcode).should == 'return value'
      end

      it "uses TargetMpFinder to find target_message with fallback" do
        @representative_finding_module.target = 'MP or Senator'
        TargetMpFinder.should_receive(:new).with([1, 2], 'JR1', true).and_return(@mock_finder)
        @mock_finder.should_receive(:target_message).with(postcode).and_return("return value")
        @representative_finding_module.target_message(postcode).should == 'return value'
      end

      it "uses TargetSenatorFinder to find target_message" do
        @representative_finding_module.target = 'Senator'
        TargetSenatorFinder.should_receive(:new).with([1, 2], 'JR1').and_return(@mock_finder)
        @mock_finder.should_receive(:target_message).with(postcode).and_return("return value")
        @representative_finding_module.target_message(postcode).should == 'return value'
      end
    end
  end


end
