require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe UserSearchQuery do

  let!(:nsw_postcode) { Postcode.create(number: "2546", longitude: "150.077", latitude: "-36.3558") }
  let!(:vic_postcode) { Postcode.create(number: "3231", longitude: "144.107", latitude: "-38.4594") }

  let!(:email_user) { create(:user, email: "kathy_white@example.com") }
  let!(:suburb_user) { create(:user, suburb: "Sydney", email: "noop1@example.com") }
  let!(:notes_user) { create(:user, notes: "DNC", email: "noop2@example.com") }
  let!(:first_name_user) { create(:user, first_name: "marceline", email: "marceline@example.com") }
  let!(:last_name_user) { create(:user, last_name: "marzipan", email: "marzipan@example.com") }
  let!(:nsw_postcode_user) { create(:user, email: "nsw@example.com", postcode_id: nsw_postcode.id) }
  let!(:vic_postcode_user) { create(:user, email: "vic@example.com", postcode_id: vic_postcode.id) }
  let!(:card_last_four_digits_user) do
    user = create(:user, email: "darren-donor@example.com") 
    create(:donation, user: user, amount_in_cents: 500, card_number: '4111111111111111') #last 4 digits:1111
    user
  end

  def search(params)
    UserSearchQuery.new(params[:query], params[:query_option], params[:first_name],
                        params[:last_name], params[:card_last_four_digits], !!params[:admins_only], !!params[:exact_match]).results
  end
  
  context "searches by email" do
    let(:params) do
      { query_option: "email" }
    end

    it "should match the complete query" do
      params.merge!(query: "kathy_white@example.com")
      search(params).all.should eq [email_user]
    end

    it "should partially match search query" do
      params.merge!(query: "white")
      search(params).all.should eq [email_user]
    end

    it "should only match the exact email address" do
      similar_email_user = User.create(email: "kathy_white@example.com.au")
      params.merge!({query: "kathy_white@example.com", exact_match: '1'})
      search(params).all.should eq [email_user]
    end
  end

  context "searches by suburb" do
    let(:params) do
      { query_option: "suburb" }
    end

    it "should match the complete query" do
      params.merge!(query: "sydney")
      search(params).all.should eq [suburb_user]
    end

    it "should partially match search query" do
      params.merge!(query: "sYd")
      search(params).all.should eq [suburb_user]
    end

    it "should only match the exact suburb" do
      similar_suburb = User.create(suburb: "Sydneyyy", email: "noop12@example.com")
      params.merge!({query: "Sydney", exact_match: '1'})
      search(params).all.should eq [suburb_user]
    end
  end

  context "searches by notes" do
    let(:params) do
      { query_option: "notes" }
    end

    it "should match the complete query" do
      params.merge!(query: "DNC")
      search(params).all.should eq [notes_user]
    end

    it "should partially match search query" do
      params.merge!(query: "DN")
      search(params).all.should eq [notes_user]
    end

    it "should only match the exact notes" do
      similar_notes = User.create(notes: "DNCAB", email: "noop232@example.com")
      params.merge!({query: "DNC", exact_match: '1'})
      search(params).all.should eq [notes_user]
    end
  end

  context "searches by postcode" do
    let(:params) do
      { query_option: "postcode" }
    end

    it "should match the complete query" do
      params.merge!(query: "2546")
      search(params).all.should eq [nsw_postcode_user]
    end
  end

  context "searches by first name" do
    let(:params) do
      { query_option: "email" }
    end

    it "exact match" do
      params.merge!(first_name: "marceline")
      search(params).all.should eq [first_name_user]
    end

    it "should partially match search query" do
      params.merge!(first_name: "marcel")
      search(params).all.should eq [first_name_user]
    end

    it "should only match the exact first name" do
      similar_first_name = User.create(first_name: "marcelinean", email: "marcelinean@example.com")
      params.merge!({first_name: "marceline", exact_match: '1'})
      search(params).all.should eq [first_name_user]
    end
  end

  context "searches by last name" do
    let(:params) do
      { query_option: "email" }
    end

    it "should match the complete query" do
      params.merge!(last_name: "marzipan")
      search(params).all.should eq [last_name_user]
    end

    it "should partially match search query" do
      params.merge!(last_name: "marzi")
      search(params).all.should eq [last_name_user]
    end

    it "should only match the exact last name" do
      similar_last_name = User.create(last_name: "marzipanea", email: "marzipanea@example.com")
      params.merge!({last_name: "marzipan", exact_match: '1'})
      search(params).all.should eq [last_name_user]
    end
  end

  context "searches by card last four digits" do
    let(:params) do
      { query_option: "email" }
    end

    it "should match the complete query" do
      params.merge!(card_last_four_digits: "1111")
      search(params).all.should eq [card_last_four_digits_user]
    end

    it "should return unique matches" do
      create(:donation, user: card_last_four_digits_user, card_number: '4111111111111111', amount_in_cents: 300)
      params.merge!(card_last_four_digits: "1111")
      search(params).all.should eq [card_last_four_digits_user]
    end
  end

  context "searches by multiple search type " do
    let!(:all_search_criteria_user) {User.create(first_name: "marceline", last_name: "marzipan", email: "kathy_white@example.com.au", notes: "DNC", is_admin: 1, postcode_id: nsw_postcode.id)}
    let!(:multiple_search_user) {User.create(first_name: "tom", email: "tom@example.com", notes: "DNC")}

    it "should return user by firstname and notes search" do
      params = {query: "DNC", first_name: "tom", query_option: "notes" }
      search(params).all.should eq [multiple_search_user]
    end

    it "should search by first name, last name, 'is admin' and notes" do
      params = {query: "DNC", first_name: 'marce', last_name: 'marz', admins_only: true, query_option: "notes"}
      results = search(params).all
      results.size.should == 1
      results.first.id.should eq all_search_criteria_user.id
    end

    it "should search by first name, last name, 'is admin' and postcode" do
      params = {query: "2546", first_name: 'marce', last_name: 'marz', admins_only: true, query_option: "postcode"}
      results = search(params).all
      results.size.should == 1
      results.first.id.should eq all_search_criteria_user.id
    end

    it "should not return any user with search by first name, last name, 'is admin' and postcode with exact match" do
      params = {query: "2546", first_name: 'marce', last_name: 'marz', admins_only: true, query_option: "postcode", exact_match: '1'}
      results = search(params).all
      results.size.should == 0
    end

    it "should search by first name, last name, 'is admin' and postcode with exact match" do
      similar_last_name = User.create(last_name: "marzipanea", email: "marzipanea@example.com")
      params = {query: "2546", first_name: 'marceline', last_name: 'marzipan', admins_only: true, query_option: "postcode", exact_match: '1'}
      results = search(params).all
      results.size.should == 1
      results.first.id.should eq all_search_criteria_user.id
    end

    it "should search by first name, last name, 'is admin' and notes with exact match" do
      similar_first_name = User.create(first_name: "marcelinean", email: "marcelinean@example.com")
      params = {query: "DNC", first_name: 'marceline', last_name: 'marzipan', admins_only: true, query_option: "notes", exact_match: '1'}
      results = search(params).all
      results.size.should == 1
      results.first.id.should eq all_search_criteria_user.id
    end
  end

  it "should sort results" do
    results = search({}).all
    sorted_users = User.all.sort { |x,y| x.id <=> y.id }

    results.should == sorted_users
  end

  context "with blank search parameters" do
    context "search options are blank" do
      it "should return all users" do
        search({query_option: 'notes', query: ''}).all.size.should == 8
        search({query_option: 'email', query: ''}).all.size.should == 8
        search({query_option: 'suburb', query: ''}).all.size.should == 8
        search({query_option: 'postcode', query: ''}).all.size.should == 8
        search({query_option: 'card_last_four_digits', query: ''}).all.size.should == 8
      end
    end
  end

  it "should return non-members as well" do
    non_member = create(:user, is_member: false)
    search({}).all.should include(non_member)
  end

  it "should handle special characters in non-exact searches" do
    percent_user = create(:user, email: 'percent-in-notes@email.com', notes: '% a note')
    search({query_option: 'notes', query: '%'}).all.should == [percent_user]

    bang_user = create(:user, email: 'bang-notes@email.com', notes: 'great! was good.')
    search({query_option: 'notes', query: '!'}).all.should == [bang_user]
  end
end
