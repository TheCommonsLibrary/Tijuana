require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe PageSequence do  
  before :each do
    @campaign = create(:campaign)
  end

  describe 'on delete' do
    it 'should delete dependants' do
      time = Time.now
      Timecop.freeze(time) do
        page_sequence = create(:page_sequence)
        page = create(:page, page_sequence: page_sequence)
        page_sequence.destroy
        expect(page.reload.deleted_at.to_date).to eql(time.to_date)
      end
    end
  end

  describe "duplicate" do
    let(:original) { create(:page_sequence_with_parent) }

    it "should copy all pages and leave the originals unchanged" do
      create(:page, name: "page1", page_sequence: original)
      create(:page, name: "page2", page_sequence: original)
      copy = original.duplicate
      original.reload
      expect(copy.pages.length).to eql(2)
      expect(original.pages.length).to eql(2)
    end

    it "should copy all content module links and leave the originals unchanged" do
      page1 = create(:page, name: "page1", page_sequence: original)
      link = create(:content_module_link, page: page1, content_module_id: 0)
      copy = original.duplicate
      original.reload
      expect(copy.pages.first.content_module_links.length).to eql(1)
      expect(original.pages.first.content_module_links.length).to eql(1)
    end

    it "should reset views on duplicated pages" do
      create(:page, name: "page1", page_sequence: original, views: 100)
      copy = original.duplicate
      expect(copy.pages.first.views).to eql(0)
    end

    it "should reset pillar status" do
      original.update_attributes!(pillar_pin: true, title: 'test', blurb: 'test', facebook_image: 'https://test')
      copy = original.duplicate
      expect(copy.pillar_pin).to be false
      expect(copy.pillar_show).to be false
    end
  end

  describe "themes" do
    let (:theme) {  create(:theme, name: "sometheme") }
    context "page_sequence has a theme" do
      it "should return theme name" do
        page_sequence = build(:page_sequence_with_parent, theme: theme)
        expect(page_sequence.theme_name).to eql("sometheme")
      end
    end

    context "page_sequence does not have a theme, but campaign does" do
      it "should return campaign theme name" do
        @campaign.theme = theme
        page_sequence = PageSequence.new(name: "No theme", campaign: @campaign, facebook_image: "http://fb.png")
        expect(page_sequence.theme_name).to eql("sometheme")
      end
    end
  end
    
  describe "validations" do
    it "should require a name between 3 and 218 characters" do
      expect(build(:page_sequence_with_parent, name: "Save the kittens!")).to be_valid
      expect(build(:page_sequence_with_parent, name: "12")).to_not be_valid
      expect(build(:page_sequence_with_parent, name: "X" * 219)).to_not be_valid
      expect(build(:page_sequence_with_parent, name: nil)).to_not be_valid
    end

    it "should require a default subject between 2 and 256 characters" do
      expect(build(:page_sequence_with_parent, email_subject: "Save the kittens!")).to be_valid
      expect(build(:page_sequence_with_parent, email_subject: "X" * 256)).to be_valid
      expect(build(:page_sequence_with_parent, email_subject: "X" * 257)).to_not be_valid
      expect(build(:page_sequence_with_parent, email_subject: "")).to_not be_valid
    end

    it "should require a default body more than 10 characters" do
      expect(build(:page_sequence_with_parent, email_body: "Save the kittens!")).to be_valid
      expect(build(:page_sequence_with_parent, email_body: "X" * 10)).to be_valid
      expect(build(:page_sequence_with_parent, email_body: "X" * 9)).to_not be_valid
      expect(build(:page_sequence_with_parent, email_body: "X" * 900)).to_not be_valid
      expect(build(:page_sequence_with_parent, email_body: "")).to_not be_valid
    end

    it "should require a tweet text between 2 and 110 characters" do
      expect(build(:page_sequence_with_parent, tweet_text: "Save the kittens!")).to be_valid
      expect(build(:page_sequence_with_parent, tweet_text: "X" * 107)).to be_valid
      expect(build(:page_sequence_with_parent, tweet_text: "X" * 111)).to_not be_valid
      expect(build(:page_sequence_with_parent, tweet_text: "")).to_not be_valid
    end

    context 'with pillar page' do
      it 'ensures facebook_image is ssl (or cdn, which is rewritten by web frontend)' do
        expect(build(:pillar_sequence, facebook_image: "http://example.com/fb.png")).to_not be_valid
        expect(build(:pillar_sequence, facebook_image: "https://example.com/fb.png")).to be_valid
        expect(build(:pillar_sequence, facebook_image: "http://cdn.getup.org.au/fb.jpg")).to be_valid
      end
    end

    context 'without pillar page' do
      it "doesn't care if image url is ssl" do
        expect(build(:page_sequence_with_parent, facebook_image: "http://example.com/fb.png")).to be_valid
      end
    end
  end
  
  it "knows that it is static pages if campaign is nil" do
    expect(create(:page_sequence, campaign: @campaign, name: "Not Static")).to_not be_static
    expect(create(:page_sequence, campaign: nil, name: "Static")).to be_static
  end
  
  it "should return a reference to the first page in the sequence" do
    original = create(:page_sequence_with_parent)
    first_page = create(:page, name: "page1", page_sequence: original)
    create(:page, name: "page2", page_sequence: original)

    original.reload
    expect(original.landing_page).to eql first_page
  end

  describe "defaults" do
    it "should have appropriate defaults" do
      page_sequence = PageSequence.new
      expect(page_sequence.tweet_text).to eql("Why don't you check out this?")
      expect(page_sequence.email_subject).to eql("Check out this GetUp! campaign")
      expect(page_sequence.email_body).to eql("Why don't you check out this?")
      expect(page_sequence.html_meta_description).to eql("An independent movement to build a progressive Australia and bring participation back into our democracy.")
    end
  end

  describe "cache behavior" do
    before(:each) do
      Rails.cache.clear
    end

    it "should load the page sequence from cache if found" do
      campaign = create(:campaign, name: 'sign this')
      page_sequence = create(:page_sequence, name: 'begin here', campaign: campaign)
      Rails.cache.write(page_sequence.cache_key, page_sequence)

      expect(PageSequence).to_not receive(:find)
      expect(PageSequence.get_from_cache(campaign, page_sequence.friendly_id)).to eql page_sequence
    end

    it "should save the page to the cache on first find" do
      campaign = create(:campaign, name: 'sign this')
      page_sequence = create(:page_sequence, name: 'begin here', campaign: campaign)

      expect(Rails.cache.read(page_sequence.cache_key)).to be_nil
      expect(PageSequence.get_from_cache(campaign, page_sequence.friendly_id)).to eql page_sequence
      expect(Rails.cache.read(page_sequence.cache_key)).to eql page_sequence
    end
  end

  describe "find_or_create_offline_donation_page" do
    it "should create the offline donations page if it does not exits" do
      page_sequence = create(:page_sequence)
      page = page_sequence.find_or_create_offline_donation_page
      expect(page.name).to eql("Offline Donations")
      expect(page).to have_a_donation
    end
    it "should find the offline donations page if it does exist" do
      page_sequence = create(:page_sequence)
      existing_page = page_sequence.find_or_create_offline_donation_page
      expect(PageSequence.find(page_sequence.id).find_or_create_offline_donation_page).to eql(existing_page)
    end
  end

  describe "reached_expiry?" do
    context "when expired boolean field true" do
      subject { create(:page_sequence_with_parent, expired: true) }
      it { expect(subject.reached_expiry?).to eql true }
    end
    context "when expired boolean field false" do
      context "and expires_at is in the future" do
        subject { create(:page_sequence_with_parent, expired: false, expires_at: Date.today + 1.days) }
        it { expect(subject.reached_expiry?).to_not eql true }
      end
      context "and expires_at is today" do
        subject { create(:page_sequence_with_parent, expired: false, expires_at: Date.today) }
        it { expect(subject.reached_expiry?).to eql true }
      end
      context "and expires_at is in the past" do
        subject { create(:page_sequence_with_parent, expired: false, expires_at: Date.today - 1.days) }
        it { expect(subject.reached_expiry?).to eql true }
      end
    end
  end

  describe('.pillar_visible') do
    let!(:default_not_shown) { create(:page_sequence_with_parent, {name: 'default_not_shown'})}
    let!(:no_pages) { create(:page_sequence_with_parent, {name: 'no_pages', pillar_show: true, title: 'a', blurb: 'b', facebook_image: 'https://example.com/fb.png'})}
    let!(:expired) { create(:pillar_sequence, {name: 'expired', pillar_show: true, expired: true})}
    let!(:expired_yesterday) { create(:pillar_sequence, {name: 'expired_yesterday', pillar_show: true, expires_at: Date.today - 1.days})}
    let!(:pinned) { create(:pillar_sequence, {created_at: Time.now - 30.seconds, name: 'pinned', pillar_pin: true})}
    let!(:shown) { create(:pillar_sequence, {created_at: Time.now - 20.seconds, name: 'shown', pillar_show: true})}
    let!(:expires_tomorrow) { create(:pillar_sequence, {created_at: Time.now - 10.seconds, name: 'expires_tomorrow', pillar_show: true, expires_at: Date.today + 1.days})}

    before do
      shown.pages << build(:page)
      shown.pages.each(&:save!)
    end

    it 'shows the right sequences, in the right order' do
      expect(PageSequence.pillar_visible.map(&:name)).to eql([
        'expires_tomorrow',
        'shown',
        'pinned',
      ])
    end
  end
end
