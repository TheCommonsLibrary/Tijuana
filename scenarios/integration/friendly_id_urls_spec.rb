require_relative "../scenario_helper"

describe "FriendlyId URLs", type: :request do
  let(:friendly_id_clash_pattern){ /friendly-page-[a-z0-9\-]{36}$/ }

  before do
    @campaign = create :campaign, name: "Friendly Campaign"
    @page_sequence = create :page_sequence, name: "Friendly Sequence", campaign: @campaign
    @page = create :page, name: "Friendly Page", page_sequence: @page_sequence
  end

  context "with #to_param monkey patch in initializers/friendly_id.rb" do
    it "ensures Page uses #id for #to_param" do
      expect(@page.to_param).to eq(@page.id.to_s)
    end

    it "ensures Event uses #friendly_id for #to_param" do
      get_together = create :get_together, name: "Friendly GetTogether"
      event = create :event, name: "Friendly Event", get_together: get_together

      expect(event.to_param).to eq("friendly-gettogether-friendly-event")
    end
  end

  it "ensures the third duplicate page works" do
    @page1 = create :page, name: "Friendly Page", page_sequence: @page_sequence
    @page2 = create :page, name: "Friendly Page", page_sequence: @page_sequence
    expect(@page.reload.friendly_id).to eq("friendly-page")
    expect(@page1.reload.friendly_id).to match(friendly_id_clash_pattern)
    expect(@page2.reload.friendly_id).to match(friendly_id_clash_pattern)
    expect(@page2.reload.friendly_id).to_not eq(@page1.reload.friendly_id)
  end

  it "finds the right page" do
    response = get "/campaigns/friendly-campaign/friendly-sequence/friendly-page"
    expect(response).to eq(200)
  end

  # History module
  context "with a renamed page" do
    before do
      @page.name = "Renamed Page"
      @page.save!
    end

    it "redirects from the old name" do
      response = get "/campaigns/friendly-campaign/friendly-sequence/friendly-page"
      expect(response).to eq(301)
    end

    it "finds the new name" do
      response = get "/campaigns/friendly-campaign/friendly-sequence/renamed-page"
      expect(response).to eq(200)
    end

    # History + Scope modules
    context "with a duplicate page name in a different page_sequence" do
      before do
        new_sequence = create :page_sequence, name: "New Sequence", campaign: @campaign
        @new_page = create :page, name: "Friendly Page", page_sequence: new_sequence
      end

      it "finds the new page" do
        response = get "/campaigns/friendly-campaign/new-sequence/friendly-page"
        expect(response).to eq(200)
        expect(controller.instance_variable_get(:@page)).to eq(@new_page)
      end
    end
  end

  context "with a renamed page_sequence that conflicts with an earlier page_sequence" do
    before do
      another_campaign = create :campaign, name: "Another Campaign"
      @another_sequence = create :page_sequence, name: "Friendly Sequence", campaign: another_campaign
      create :page, name: "Another Page", page_sequence: @another_sequence
      @another_sequence.name = "Renamed Sequence"
      @another_sequence.save!
    end

    it "redirects from the original" do
      response = get "/campaigns/another-campaign/friendly-sequence/another-page"
      expect(response).to eq(301)
      expect(controller.instance_variable_get(:@page_sequence)).to eq(@another_sequence)
    end

    it "finds the rename" do
      response = get "/campaigns/another-campaign/renamed-sequence/another-page"
      expect(response).to eq(200)
      expect(controller.instance_variable_get(:@page_sequence)).to eq(@another_sequence)
    end
  end

  context "with a renamed page that conflicts with an earlier page" do
    before do
      another_campaign = create :campaign, name: "Another Campaign"
      another_sequence = create :page_sequence, name: "Another Sequence", campaign: another_campaign
      @another_page = create :page, name: "Friendly Page", page_sequence: another_sequence
      @another_page.name = "Renamed Page"
      @another_page.save!
    end

    it "redirects from the original" do
      response = get "/campaigns/another-campaign/another-sequence/friendly-page"
      expect(response).to eq(301)
      expect(controller.instance_variable_get(:@page)).to eq(@another_page)
    end

    it "finds the rename" do
      response = get "/campaigns/another-campaign/another-sequence/renamed-page"
      expect(response).to eq(200)
      expect(controller.instance_variable_get(:@page)).to eq(@another_page)
    end
  end

  # Scope module
  context "with a duplicate page name in a different page_sequence" do
    before do
      another_sequence = create :page_sequence, name: "Another Sequence", campaign: @campaign
      @another_page = create :page, name: "Friendly Page", page_sequence: another_sequence
    end

    it "finds the original page" do
      response = get "/campaigns/friendly-campaign/friendly-sequence/friendly-page"
      expect(response).to eq(200)
      expect(controller.instance_variable_get(:@page)).to eq(@page)
    end

    it "finds the duplicate page" do
      response = get "/campaigns/friendly-campaign/another-sequence/friendly-page"
      expect(response).to eq(200)
      expect(controller.instance_variable_get(:@page)).to eq(@another_page)
    end
  end

  # FriendlyId 3/4 Sequence generation
  context "with a duplicate page name in the same page_sequence" do
    before do
      @dup_page = create :page, name: "Friendly Page", page_sequence: @page_sequence
    end

    it "finds the original page" do
      response = get "/campaigns/friendly-campaign/friendly-sequence/friendly-page"
      expect(response).to eq(200)
    end

    it "finds the duplicate page" do
      response = get "/campaigns/friendly-campaign/friendly-sequence/#{@dup_page.friendly_id}"
      expect(response).to eq(200)
    end

    it "gets labelled the right way around" do
      expect(@page.friendly_id).to eq("friendly-page")
      expect(@dup_page.friendly_id).to match(friendly_id_clash_pattern)
    end
  end

  context "with a duplicate page_sequence name in the same campaign" do
    before do
      @dup_sequence = create :page_sequence, name: "Friendly Sequence", campaign: @campaign
      create :page, name: "Friendly Page", page_sequence: @dup_sequence
    end

    it "finds the original page_sequence" do
      response = get "/campaigns/friendly-campaign/friendly-sequence/friendly-page"
      expect(response).to eq(200)
    end

    it "finds the duplicate page_sequence" do
      response = get "/campaigns/friendly-campaign/#{@dup_sequence.friendly_id}/friendly-page"
      expect(response).to eq(200)
    end

    it "gets labelled the right way around" do
      expect(@page_sequence.friendly_id).to eq("friendly-sequence")
      expect(@dup_sequence.friendly_id).to match(/friendly-sequence-[a-z0-9\-]{36}$/)
    end
  end
end
