require File.dirname(__FILE__) + "/scenario_helper.rb"

describe "Content-modules", type: :feature, js: true do
  before do
    @campaign = create(:campaign)
    @page_sequence = create(:page_sequence, campaign: @campaign, theme: create(:theme))
    @page_with_standfirst_module = create(:page, name: 'standfirst test page', page_sequence: @page_sequence, position: 1)
  end
  context "Standfirst-module as main content" do
    before do
      @standfirst_module = StandfirstModule.create!(content: 'This is the standfirst content')
      ContentModuleLink.create!(page: @page_with_standfirst_module, content_module: @standfirst_module, position: 1, layout_container: :main_content)
    end

    it 'should display the standfirst module in the main content of the public view' do
      visit page_path(@campaign.id, @page_sequence.id, @page_with_standfirst_module.id)
      page.should have_content @standfirst_module.content
    end
    
    
  end

  context "Without Standfirst-module" do
    before do
      @page = create(:page, :page_sequence => @page_sequence)
      @content_module = HtmlModule.create!(content: "This is HtmlModule content")
      @ask_content_module = create(:petition_module)
      ContentModuleLink.create!(page: @page, content_module: @content_module, position: 1, layout_container: :main_content)
      ContentModuleLink.create!(page: @page, content_module: @ask_content_module, layout_container: :sidebar)
    end

    it 'should display standfirst content in the main content of the public view' do
      resize_window *mobile_portrait_size
      visit page_path(@campaign.id, @page_sequence.id, @page.id)
      page.should have_content @content_module.content
      page.find(".standfirst-module").text.should =~ /HtmlModule content/
    end
    
  end
end
