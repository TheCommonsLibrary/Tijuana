require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe MpsController do
  before(:each) do
    @federal_jurisdiction = create(:getup_jurisdiction)
    @federal_jurisdiction.parties << Party.create!(:name => "tea party", :abbreviation => "TEA")
    @federal_jurisdiction.save!

    @nsw_jurisdiction = create(:getup_nsw_jurisdiction)
    @party1 = create(:party)

    @email_mp_module = create(:email_mp_module, :jurisdiction_code => @federal_jurisdiction.code)
    @call_mp_module = create(:call_mp_module, :jurisdiction_code => @federal_jurisdiction.code)
    @electorate1 = create(:sydney_federal, :jurisdiction => @federal_jurisdiction)
    @electorate2 = create(:sydney_local, :jurisdiction => @nsw_jurisdiction)

    @sydney_federal_region = create(:sydney_federal_region, :jurisdiction => @federal_jurisdiction)

    @mp1 = create(:mp, :first_name => "Colonel", :last_name => "Bobson", :email => "rickybobby@numberone.com", :electorate => @electorate1, :party => @party1)
    @postcode1 = create(:postcode, :electorates => [@electorate1, @electorate2], :regions => [@sydney_federal_region])
  end

  describe "identify_module" do
    it "should render 404 if module_id is not existing" do
      @email_mp_module = nil
      @call_mp_module = nil
      get :select_senator
      response.body.should =~ /We couldn't find that page!/
    end
  end

  render_views
  describe "lookup an mp for a postcode checking against target parties" do
    it "should return an error if the user enters an invalid postcode" do
      get :lookup, {:postcode => 99999, :module_id => @email_mp_module.id}
      @msg = assigns(:msg)
      @msg.should =~ /Please enter a valid postcode./
      @target_options = assigns(:target_options)
      @target_options.should be_nil
      @target = assigns(:target)
      @target.should be_nil
    end

    describe "single electorate matches postcode" do
      it "should return the name of an mp if matches target party" do
        @email_mp_module.target_party_ids = {@mp1.party.id => '1'}
        @email_mp_module.save!
        get :lookup, {:postcode => @postcode1.number, :module_id => @email_mp_module.id}
        response.body.should =~ /Your email will go to Colonel Bobson./
        @target_options = assigns(:target_options)
        @target_options.should be_blank
        @target = assigns(:target)
        @target.should == @mp1
      end

      describe "mp does not match target parties" do
        it "should return an error if not falling back to senate" do
          get :lookup, {:postcode => @postcode1.number, :module_id => @email_mp_module.id}
          @msg = assigns(:msg)
          @msg.should =~ /Colonel Bobson does not represent one of the target parties of this campaign/
          @msg.should_not =~ /select a Senator/
          @target_options = assigns(:target_options)
          @target_options.should be_blank
          @target = assigns(:target)
          @target.should be_nil
        end

        it "should return an error if falling back, but nothing to fall back to" do
          @email_mp_module.target_senate = '1'
          @email_mp_module.save!
          get :lookup, {:postcode => @postcode1.number, :module_id => @email_mp_module.id}
          @msg = assigns(:msg)
          @msg.should =~ /Colonel Bobson does not represent one of the target parties of this campaign/
          @msg.should =~ /neither are any of your senators/
          @target_options = assigns(:target_options)
          @target_options.should be_blank
          @target = assigns(:target)
          @target.should be_nil
        end

        it "should return a list of senators if falling back, and multiple options" do
          party2 = create(:party, :abbreviation => "PARTY2")
          @senator1 = create(:senator, :first_name => "Aimee", :region => @sydney_federal_region, :party => party2)
          @senator2 = create(:senator, :first_name => "Bart", :region => @sydney_federal_region, :party_id => @senator1.party.id)

          @email_mp_module.target_senate = '1'
          @email_mp_module.target_party_ids = {@senator1.party.id => '1'}
          @email_mp_module.save!
          get :lookup, {:postcode => @postcode1.number, :module_id => @email_mp_module.id}
          @msg = assigns(:msg)
          @msg.should =~ /Colonel Bobson does not represent one of the target parties of this campaign/
          @msg.should =~ /select a Senator/
          @target_options = assigns(:target_options)
          @target_options.should_not be_nil
          @target = assigns(:target)
          @target.should be_nil
        end

        it "should return the name of a senator if falling back and only one option" do
          party2 = create(:party, :abbreviation => "PARTY2")
          @senator1 = create(:senator, :first_name => "Guido", :last_name => "Anchovy", :region => @sydney_federal_region, :party => party2)
          @email_mp_module.target_senate = '1'
          @email_mp_module.target_party_ids = {@senator1.party.id => '1'}
          @email_mp_module.save!
          get :lookup, {:postcode => @postcode1.number, :module_id => @email_mp_module.id}
          response.body.should =~ /Colonel Bobson does not represent one of the target parties of this campaign/
          response.body.should =~ /Your email will go to Senator/
          @target_options = assigns(:target_options)
          @target_options.should be_blank
          @target = assigns(:target)
          @target.should_not be_nil
        end

        describe "user selects one of the senators" do
          it "should return the name of a senator that is selected" do
            party2 = create(:party, :abbreviation => "PARTY2")
            @senator1 = create(:senator, :region => @sydney_federal_region, :first_name => "Speedy", :last_name => "Cerviche", :party => party2)
            @senator2 = create(:senator, :region => @sydney_federal_region, :party_id => @senator1.party.id)
            @email_mp_module.target_senate = '1'
            @email_mp_module.target_party_ids = {@senator1.party.id => '1'}
            @email_mp_module.save!
            get :lookup, {:postcode => @postcode1.number, :module_id => @email_mp_module.id}
            @target_options = assigns(:target_options)
            get :select_senator, {:fallback_id => @target_options[0].id, :module_id => @email_mp_module.id}
            @msg = assigns(:msg)
            @msg.should == "Your email will go to Senator #{@target_options[0].first_name} #{@target_options[0].last_name}."
            @target = assigns(:target)
            @target.should_not be_nil
          end

          it "should return the name of a senator that is selected, with their phone number" do
            party2 = create(:party, :abbreviation => "PARTY2")

            @senator1 = create(:senator, :region => @sydney_federal_region, :first_name => "Speedy", :last_name => "Cerviche", :party => party2)
            @senator2 = create(:senator, :region => @sydney_federal_region, :party_id => @senator1.party.id)
            @call_mp_module.target_senate = '1'
            @call_mp_module.target_party_ids = {@senator1.party.id => '1'}
            @call_mp_module.save!
            get :lookup, {:postcode => @postcode1.number, :module_id => @call_mp_module.id}
            @target_options = assigns(:target_options)
            senator = Senator.find(@target_options[0].id)
            get :select_senator, {:fallback_id => @target_options[0].id, :module_id => @call_mp_module.id}
            @msg = assigns(:msg)
            @msg.should match /Please call your Senator/
            @msg.should match /#{senator.full_name}/
            @msg.should match /\(08\) 93074839/
            @target = assigns(:target)
            @target.should_not be_nil
          end

          it "should return the name of a senator that is selected, with their office address" do
            party2 = create(:party, :abbreviation => "PARTY2")

            @senator1 = create(:senator, :region => @sydney_federal_region, :first_name => "Speedy", :last_name => "Cerviche", :party => party2)
            @senator2 = create(:senator, :region => @sydney_federal_region, :party_id => @senator1.party.id)
            @call_mp_module.target_senate = '1'
            @call_mp_module.target_phone = 'office'
            @call_mp_module.contact_method = 'visit'
            @call_mp_module.target_party_ids = {@senator1.party.id => '1'}
            @call_mp_module.save!
            get :lookup, {:postcode => @postcode1.number, :module_id => @call_mp_module.id}
            @target_options = assigns(:target_options)
            senator = Senator.find(@target_options[0].id)
            get :select_senator, {:fallback_id => @target_options[0].id, :module_id => @call_mp_module.id}
            @msg = assigns(:msg)
            @msg.should match /Office details for your Senator/
            @msg.should match /#{senator.full_name}/
            @msg.should match /\(08\) 93074839/
            @msg.should match /#{senator.office_address}/
            @target = assigns(:target)
            @target.should_not be_nil
          end

          context 'with contact method set to mail' do
            it "should return the name of a senator that is selected, with both their office and postal addresses" do
              party2 = create(:party, :abbreviation => "PARTY2")
              @senator1 = create(:senator, :region => @sydney_federal_region, :first_name => "Speedy", :last_name => "Cerviche", :party => party2, mailing_address: 'test')
              @senator2 = create(:senator, :region => @sydney_federal_region, :party_id => @senator1.party.id, mailing_address: 'test')
              @call_mp_module.target_senate = '1'
              @call_mp_module.target_phone = 'office'
              @call_mp_module.contact_method = 'mail'
              @call_mp_module.target_party_ids = {@senator1.party.id => '1'}
              @call_mp_module.save!
              get :lookup, {:postcode => @postcode1.number, :module_id => @call_mp_module.id}
              @target_options = assigns(:target_options)
              senator = Senator.find(@target_options[0].id)
              get :select_senator, {:fallback_id => @target_options[0].id, :module_id => @call_mp_module.id}
              @msg = assigns(:msg)
              @msg.should match /hand deliver/
              @msg.should match /#{senator.full_name}/
              expect(@msg).to include(senator.mailing_address)
              @msg.should match /postal/
              @msg.should match /#{senator.full_name}/
              @msg.should match /#{senator.office_address}/
              @target = assigns(:target)
              @target.should_not be_nil
            end
          end
        end
      end
    end

    describe "multiple MPs that have same electorate and postcode" do
      it "should show only the targeted MPs" do
        other_party = create(:party, :abbreviation => "other")
        second_mp = create(:mp, :first_name => "Colonel", :last_name => "Bobson", :email => "rickybobby@numberone.com", :electorate => @electorate1, :party => @party1)
        third_mp = create(:mp, :first_name => "Bob", :last_name => "Builder", :email => "bobbuilder@example.com", :electorate => @electorate1, :party => other_party)
        other_postcode = create(:postcode, :electorates => [@electorate1], :regions => [@sydney_federal_region])
        @email_mp_module.target_party_ids = {@party1.id => '1'}
        @email_mp_module.save!
        get :lookup, {:postcode => other_postcode.number, :module_id => @email_mp_module.id}
        assigns(:msg).should =~ /select your representative/
        assigns(:msg).should_not =~ /crosses electorates/
        @target_options = assigns(:target_options)
        @target_options.count.should == 2
        @target_options.should include(@mp1, second_mp)
        @target = assigns(:target)
        @target.should be_nil
      end

    end

    describe "multiple electorates match postcode" do
      before(:each) do
        @party2 = create(:party, :abbreviation => "PARTY2")
        @electorate3 = create(:sydney_federal_second, :jurisdiction => @federal_jurisdiction)
        @mp2 = create(:mp, :first_name => "Captain", :last_name => "Bobtacular", :electorate => @electorate3, :party => @party2, :parliament_phone => "123", :office_phone => "234")

        @electorate3.postcodes << @postcode1
      end

      it "should show all the MPs if there is no MPs in the target parties" do
        @email_mp_module.target_party_ids = {@party1.id => '1'}
        @email_mp_module.save!
        get :lookup, {:postcode => @postcode1.number, :module_id => @email_mp_module.id}
        assigns(:msg).should =~ /crosses electorates/
        assigns(:msg).should =~ /select your representative/
        @target_options = assigns(:target_options)
        @target_options.count.should == 2
        @target_options.should include(@mp1, @mp2)
        @target = assigns(:target)
        @target.should be_nil
      end

      it "should only show the MPs in the target parties" do
        @email_mp_module.target_party_ids = {@party1.id => '1', @party2.id => '1'}
        @email_mp_module.save!
        get :lookup, {:postcode => @postcode1.number, :module_id => @email_mp_module.id}
        assigns(:msg).should =~ /postcode crosses electorates/
        @target_options = assigns(:target_options)
        @target_options.count.should == 2
        @target_options.should include(@mp1, @mp2)
        @target = assigns(:target)
        @target.should be_nil
      end

      it "should show possible mps" do
        @email_mp_module.target_party_ids = {@mp1.party.id => '1', @mp2.party.id => '1'}
        @email_mp_module.save!
        get :lookup, {:postcode => @postcode1.number, :module_id => @email_mp_module.id}
        @msg = assigns(:msg)
        @msg.should =~ /postcode crosses electorates/
        @target_options = assigns(:target_options)
        @target_options.should_not be_nil
        @target = assigns(:target)
        @target.should be_nil
      end

      describe "at least one of the mps matches the target party" do
        before(:each) do
          @email_mp_module.target_party_ids = {@mp1.party.id => '1'}
          @email_mp_module.save!
          @call_mp_module.target_party_ids = {@mp1.party.id => '1'}
          @call_mp_module.save!
          get :lookup, {:postcode => @postcode1.number, :module_id => @email_mp_module.id}
        end

        describe "the user has selected one of the options" do
          it "should return the name of the mp if matches target party when sending an email" do
            get :ensure_in_target_party, {:mp_id => @mp1.id, :module_id => @email_mp_module.id, :postcode => @postcode1.number}
            @msg = assigns(:msg)
            response.body.should =~ /Your email will go to Colonel Bobson./
            @target_options = assigns(:target_options)
            @target_options.should be_blank
            @target = assigns(:target)
            @target.should == @mp1
          end

          it "should return the name of the mp plus phone number if matches target party" do
            get :ensure_in_target_party, {:mp_id => @mp1.id, :module_id => @call_mp_module.id, :postcode => @postcode1.number}
            @msg = assigns(:msg)
            response.body.should match /Please call your MP/
            response.body.should match /Colonel Bobson/
            response.body.should match /\(08\) 93074839/
            @target_options = assigns(:target_options)
            @target_options.should be_blank
            @target = assigns(:target)
            @target.should == @mp1
          end

          describe "selected mp does not match target parties" do
            it "should return an error if not falling back to senate" do
              get :ensure_in_target_party, {:mp_id => @mp2.id, :module_id => @email_mp_module.id, :postcode => @postcode1.number}
              @msg = assigns(:msg)
              @msg.should =~ /Captain Bobtacular does not represent one of the target parties of this campaign/
              @msg.should_not =~ /select a Senator/
              @target_options = assigns(:target_options)
              @target_options.should be_blank
              @target = assigns(:target)
              @target.should be_nil
            end

            it "should return an error if falling back, but nothing to fall back to" do
              @email_mp_module.target_senate = '1'
              @email_mp_module.save!
              @senator = create(:senator, :region => @sydney_federal_region, :state => "WA")
              get :ensure_in_target_party, {:mp_id => @mp2.id, :module_id => @email_mp_module.id, :postcode => @postcode1.number}
              @msg = assigns(:msg)
              @msg.should =~ /Captain Bobtacular does not represent one of the target parties of this campaign/
              @msg.should =~ /neither are any of your Senators/
              @target_options = assigns(:target_options)
              @target_options.should be_blank
              @target = assigns(:target)
              @target.should be_nil
            end

            def target_senate(postcode)
              @email_mp_module.target_senate = '1'
              @email_mp_module.save!
              @senator1 = create(:senator, :region => @sydney_federal_region, :state => "NSW", :party_id => @mp1.party.id)
              @senator2 = create(:senator, :region => @sydney_federal_region, :state => "NSW", :party_id => @mp1.party.id)
              get :ensure_in_target_party, {:mp_id => @mp2.id, :module_id => @email_mp_module.id, :postcode => postcode}
            end

            it "should handle spaces in postcode" do
              target_senate(" " + @postcode1.number)
              assigns(:msg).should =~ /select a Senator/
            end

            it "should handle invalid postcodes" do
              target_senate("BADCODE")
              assigns(:msg).should =~ /BADCODE is not valid/
            end

            it "should return a list of senators if falling back, and multiple options" do
              target_senate(@postcode1.number)
              @msg = assigns(:msg)
              @msg.should =~ /Captain Bobtacular does not represent one of the target parties of this campaign/
              @msg.should =~ /select a Senator/
              @target_options = assigns(:target_options)
              @target_options.should_not be_nil
              @target = assigns(:target)
              @target.should be_nil
            end

            it "should return the name of a senator with a call action and number if falling back and only one option" do
              @call_mp_module.target_senate = '1'
              @call_mp_module.save!
              @senator1 = create(:senator, :region => @sydney_federal_region, :state => "NSW", :party_id => @mp1.party.id, :first_name => "Speedy", :last_name => "Cerviche")
              get :ensure_in_target_party, {:mp_id => @mp2.id, :module_id => @call_mp_module.id, :postcode => @postcode1.number}
              @msg = assigns(:msg)

              @msg.should match /Captain Bobtacular does not represent one of the target parties/
              response.body.should match /Please call your Senator/
              response.body.should match /Speedy Cerviche/
              response.body.should match /\(08\) 93074839/

              @target_options = assigns(:target_options)
              @target_options.should be_blank
              @target = assigns(:target)
              @target.should_not be_nil
            end

            it "should return the name of a senator with an email action if falling back and only one option" do
              @email_mp_module.target_senate = '1'
              @email_mp_module.save!
              @senator1 = create(:senator, :region => @sydney_federal_region, :state => "NSW", :party_id => @mp1.party.id, :first_name => "Speedy", :last_name => "Cerviche")
              get :ensure_in_target_party, {:mp_id => @mp2.id, :module_id => @email_mp_module.id, :postcode => @postcode1.number}
              @msg = assigns(:msg)
              @msg.should =~ /Captain Bobtacular does not represent one of the target parties of this campaign/
              response.body.should =~ /Your email will go to Senator/
              @target_options = assigns(:target_options)
              @target_options.should be_blank
              @target = assigns(:target)
              @target.should_not be_nil
            end
          end
        end
      end

      describe "none of the mps matches the target party" do
        it "should return an error if not falling back to senate" do
          get :lookup, {:postcode => @postcode1.number, :module_id => @email_mp_module.id}
          @msg = assigns(:msg)
          @msg.should =~ /does not represent one of the target parties of this campaign/
          @msg.should_not =~ /select a Senator/
          @target_options = assigns(:target_options)
          @target_options.should be_blank
          @target = assigns(:target)
          @target.should be_nil
        end

        it "should return an error if falling back, but nothing to fall back to" do
          @email_mp_module.target_senate = '1'
          @email_mp_module.save!
          @senator = create(:senator, :region => @sydney_federal_region, :state => "WA")
          get :lookup, {:postcode => @postcode1.number, :module_id => @email_mp_module.id}
          @msg = assigns(:msg)
          @msg.should =~ /does not represent one of the target parties of this campaign/
          @msg.should =~ /neither are any of your senators/
          @target_options = assigns(:target_options)
          @target_options.should be_blank
          @target = assigns(:target)
          @target.should be_blank
        end

        it "should return a list of senators if falling back, and multiple options" do
          party = create(:party, :abbreviation => "PARTY3")
          @email_mp_module.target_senate = '1'
          @email_mp_module.target_party_ids = {party.id => '1'}
          @email_mp_module.save!

          perth_federal_region = create(:perth_federal_region, :jurisdiction => @federal_jurisdiction)
          @senator1 = create(:senator, :first_name => "1", :region => @sydney_federal_region, :state => "NSW", :party_id => party.id)
          @senator2 = create(:senator, :first_name => "2", :region => @sydney_federal_region, :state => "NSW", :party_id => party.id)
          @senator3 = create(:senator, :first_name => "3", :region => perth_federal_region, :state => "WA", :party_id => party.id)
          @senator4 = create(:senator, :first_name => "4", :region => @sydney_federal_region, :state => "NSW", :party_id => @mp2.party.id)
          get :lookup, {:postcode => @postcode1.number, :module_id => @email_mp_module.id}
          @msg = assigns(:msg)
          @msg.should =~ /does not represent one of the target parties of this campaign/
          @msg.should =~ /select a Senator/
          @target_options = assigns(:target_options)
          @target_options.should_not be_nil
          @target_options.count.should == 2
          @target = assigns(:target)
          @target.should be_nil
        end

        it "should return the name of a senator if falling back and only one option" do
          party = create(:party, :abbreviation => "PARTY3")
          @email_mp_module.target_senate = '1'
          @email_mp_module.target_party_ids = {party.id => '1'}
          @email_mp_module.save!
          @senator1 = create(:senator, :region => @sydney_federal_region, :state => "NSW", :party_id => party.id, :first_name => "Speedy", :last_name => "Cerviche")
          get :lookup, {:postcode => @postcode1.number, :module_id => @email_mp_module.id}
          response.body.should =~ /does not represent one of the target parties of this campaign/
          response.body.should =~ /Your email will go to Senator/
          @target_options = assigns(:target_options)
          @target_options.should be_blank
          @target = assigns(:target)
          @target.should_not be_nil
        end

      end

    end

  end

end
