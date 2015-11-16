require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe SendgridTokenReplacement do
  include SendgridTokenReplacement

  it "should handle emails addresses with different casing" do
    email = create(:email_with_tokens)
    create(:user, :email=> 'kieren@getup.org.au', :first_name=>'Kieren')

    options = {
      :test => true,
      :recipients => ['kieren@Getup.org.au']
    }
    get_substitutions_list(email, options)["{NAME|Friend}"].should == ["Kieren"]
  end

  it "should not have any subsitutions if there are no recipients" do
    email = create(:email_with_tokens)
    options = {
      :test => false,
      :recipients => []
    }
    get_substitutions_list(email, options).should be_empty
  end

  it "should always contain the tracking info in the substitutions hash" do
    user1 = create(:leo, :first_name => "Donald")
    user2 = create(:brazilian_dude, :first_name => "Steve")
    email_to_send = create(:email_with_tokens, :body => "No links here")
    user1_hash = EmailTrackingToken.encode(user1.id, email_to_send.id)
    user2_hash = EmailTrackingToken.encode(user2.id, email_to_send.id)
    users = User.includes(:postcode).select("users.id, users.first_name, users.last_name, postcodes.number").where("email in (?)", [user1.email, user2.email]).order("users.id").references(:postcode)

    expected_hash = {
                       "{NAME|Friend}" => ["Donald", "Steve"],
                       "{TRACKING_HASH|NOT_AVAILABLE}" => [user1_hash, user2_hash],
                       "{EMAIL|NOT_AVAILABLE}"=>[user1.email, user2.email]
                    }

    generate_replacement_tokens(email_to_send, users).should == expected_hash
  end

  it "should generate substitutions hash based on the email body and the given users" do
    user1 = create(:leo, :first_name => "Donald")
    user2 = create(:brazilian_dude, :first_name => "Steve")
    email_to_send = create(:email_with_tokens)
    user1_hash = EmailTrackingToken.encode(user1.id, email_to_send.id)
    user2_hash = EmailTrackingToken.encode(user2.id, email_to_send.id)
    users = User.includes(:postcode).select("users.id, users.first_name, users.last_name, postcodes.number").where("email in (?)", [user1.email, user2.email]).order("users.id").references(:postcode)

    expected_hash = {
                       "{NAME|Friend}" => ["Donald", "Steve"],
                       "{POSTCODE|Nowhere}" => ["9999", "9999"],
                       "{TRACKING_HASH|NOT_AVAILABLE}" => [user1_hash, user2_hash],
                       "{EMAIL|NOT_AVAILABLE}"=>[user1.email, user2.email]
                    }

    generate_replacement_tokens(email_to_send, users).should == expected_hash
  end

  it "should generate substitutions hash with default values based on the email body and the given users" do
    email_to_send = create(:email_with_tokens)
    expected_hash = {
                       "{NAME|Friend}" => ["Friend"],
                       "{POSTCODE|Nowhere}" => ["Nowhere"],
                       "{TRACKING_HASH|NOT_AVAILABLE}" => ["NOT_AVAILABLE"],
                       "{EMAIL|NOT_AVAILABLE}"=>["NOT_AVAILABLE"]
                    }

    generate_replacement_tokens(email_to_send, []).should == expected_hash
  end

  describe "#get_substitutions_list" do
    it "should return default tokens for test blasts" do
      email_to_send = create(:email_with_tokens)
      user1 = create(:leo, :first_name => "Leonardo")
      expected_hash = {
                       "{NAME|Friend}" => ["Friend", "Leonardo"],
                       "{POSTCODE|Nowhere}" => ["Nowhere", "9999"],
                       "{TRACKING_HASH|NOT_AVAILABLE}" => ["NOT_AVAILABLE", "NOT_AVAILABLE" ],
                       "{EMAIL|NOT_AVAILABLE}" => ["NOT_AVAILABLE", "NOT_AVAILABLE" ]
                    }

      get_substitutions_list(email_to_send, :recipients => ["non-member@gmail.com", user1.email], :test => true).should == expected_hash
    end

    it "should scan the subject line for tokens" do
      email_to_send = create(:email_with_tokens, :body => "no tokens", :subject => "Hey, {NAME|Friend}!")
      user1 = create(:leo, :first_name => "Leonardo")
      expected_hash = {
        "{TRACKING_HASH|NOT_AVAILABLE}" => ["NOT_AVAILABLE", "NOT_AVAILABLE"], 
        "{EMAIL|NOT_AVAILABLE}" => ["NOT_AVAILABLE", "NOT_AVAILABLE"], 
        "{NAME|Friend}" => ["Friend", "Leonardo"]
      }

      get_substitutions_list(email_to_send, :recipients => ["non-member@gmail.com", user1.email], :test => true).should == expected_hash
    end
  end

  describe "secure tokens" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:body) { "Pls click <a href=\"http://somewhere.com\">http://somewhere.com</a>" }
    let(:email) { create(:email_with_tokens, :secure_links, {subject: "hi", body: body}) }

    it "returns real tokens" do
      user1_hash = EmailTrackingToken.encode(user1.id, email.id)
      user2_hash = EmailTrackingToken.encode(user2.id, email.id)
      user1_secure_token = SecureLinkToken.token(user1_hash)
      user2_secure_token = SecureLinkToken.token(user2_hash)

      expected_hash = {"{TRACKING_HASH|NOT_AVAILABLE}" => [user1_hash, user2_hash],
                       "{EMAIL|NOT_AVAILABLE}"=>[user1.email, user2.email],
                       "{SECURE_TOKEN|NOT_AVAILABLE}" => [user1_secure_token, user2_secure_token]}
      expect(
        generate_replacement_tokens(email, [user1, user2])
      ).to eq expected_hash
    end

    it "returns NOT_AVAILABLE in test mode" do
      expected_hash = {"{TRACKING_HASH|NOT_AVAILABLE}" => ["NOT_AVAILABLE", "NOT_AVAILABLE" ],
                       "{EMAIL|NOT_AVAILABLE}" => ["NOT_AVAILABLE", "NOT_AVAILABLE" ],
                       "{SECURE_TOKEN|NOT_AVAILABLE}" => ["NOT_AVAILABLE", "NOT_AVAILABLE" ]}
      expect(
        generate_replacement_tokens(email, [user1, user2], [user1, user2])
      ).to eq expected_hash
    end
  end

  describe "CHIP_IN token" do
    let(:body) { "Pls {CHIP_IN|Throw in} for our office puppies" }
    let(:email) { create(:email_with_tokens, :secure_links, {subject: "hi", body: body}) }

    context "for a donor" do
      let(:user) { create(:donation).user }

      it "returns the default text" do
        replaced_text = generate_replacement_tokens(email, [user])
        expect(replaced_text["{CHIP_IN|Throw in}"]).to eq(["Throw in"])
      end
    end

    context "for a non donor" do
      let(:user) { create(:user) }

      it "returns the default text with ' $12' appended" do
        replaced_text = generate_replacement_tokens(email, [user])
        expect(replaced_text["{CHIP_IN|Throw in}"]).to eq(["Throw in $12"])
      end
    end
  end

  describe "merge token" do
    let(:user_with_postcode) { create(:leo) }
    let(:user_without_postcode) { create(:user) }
    let(:email) { create(:email, body: 'test {MERGE:postcode.number|your postcode}') }
    before(:each) do
      Setting[:whitelist_merge_tokens] = "postcode.number\nblahblah"
    end

    it "returns code executed on the user" do
      replaced_text = generate_replacement_tokens(email, [user_with_postcode, user_without_postcode])
      expect(replaced_text['{MERGE:postcode.number|your postcode}']).to eq([user_with_postcode.postcode.number, 'your postcode'])
    end

    context "with the execution throwing an error" do
      let(:user) { create(:user) }
      let(:email) { create(:email, body: 'test {MERGE:blahblah|default}') }

      it "should rescue with the default text" do
        replaced_text = generate_replacement_tokens(email, [user])
        expect(replaced_text['{MERGE:blahblah|default}']).to eq(['default'])
      end
    end

    context "with the value being a link" do
      let!(:merge_link){ 'https://mergelink.com' }
      let!(:default_link){ 'https://defaultlink.com?a=b' }
      let!(:merge_tag){ "{MERGE:merge('hospitals','action_link')|#{default_link}}" }
      let!(:email) { create(:email, body: "test <a href=\"#{merge_tag}\">hey</a>") }
      let!(:merge){ create(:merge_with_whitelist, join_key: 'postcode_id') }
      let!(:user_with_merge_record){ create(:user, postcode: create(:postcode_of_circular_quay)) }
      let!(:user_with_no_merge_record){ create(:user) }
      let!(:user_1_token){ EmailTrackingToken.encode(user_with_merge_record.id, email.id) }
      let!(:user_2_token){ EmailTrackingToken.encode(user_with_no_merge_record.id, email.id) }
      let!(:merge_record){ create(:merge_record, merge: merge, join_id: user_with_merge_record.postcode_id, name: 'action_link', value: merge_link) }

      it "should add a tracking token" do
        puts "whitelist: #{Setting[:whitelist_merge_tokens]}"
        puts "email: #{email.inspect}"
        puts "user: #{user_with_merge_record.inspect}"
        puts "merge_record: #{merge_record.inspect}"
        puts "eval: #{user_with_merge_record.instance_eval("merge('hospitals','action_link')") rescue 'failed'}"
        MergeCache.clear(merge)
        replaced_text = generate_replacement_tokens(email, [user_with_merge_record, user_with_no_merge_record])
        expect(replaced_text[merge_tag]).to include( 
          "#{merge_link}?t=#{user_1_token}", "#{default_link}&t=#{user_2_token}"
        )
      end
    end

    context "with a non-whitelist token" do
      let(:email) { build(:email, body: 'test {MERGE:email|your postcode}') }

      it "should raise an error" do
        expect {
          generate_replacement_tokens(email, [create(:user)])
        }.to raise_error(InvalidMergeToken)
      end
    end
  end
end
