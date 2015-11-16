require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe Admin::PushesHelper do
  it "should return a valid link for an existing list" do
    list = List.new
    list.save
    blast = create(:blast, :list => list)


    expected_html = %Q{<a href="/admin/list_cutter/edit?list_id=#{list.id}">Edit List</a>}
    helper.link_to_create_or_update(blast).should == expected_html
  end

  it "should return a link to create a new list" do
    blast = create(:blast)

    expected_html = %Q{<a href="/admin/list_cutter/new?blast_id=#{blast.id}">Cut a list</a>}
    helper.link_to_create_or_update(blast).should == expected_html
  end

  it "should return a formatted member count for a list" do
    list = List.create!
    blast = create(:blast, :list => list)
    list.list_intermediate_results.create!(:data => {:size => 521})
    helper.member_count(blast).should == "(521 members)"
  end
  
  it "should return empty string for member count when no list" do
    blast = create(:blast)
    helper.member_count(blast).should == ""
  end

  describe "#can_send" do
    it "should display message when there is no list for a blast" do
      blast = create(:blast)
      helper.can_send(blast).should == "<div class='email-send'><p>Blast requires a list in order to send.</p></div>"
    end

    it "should display message when there are no proofed emails" do
      blast = create(:blast, list: create(:list))
      helper.can_send(blast).should == "<div class='email-send'><p>There are no proofed emails ready to send</p></div>"
    end

    it "should display a message when there are other blasts running" do
      push = create(:push)
      email = create(:email)
      email.send_test!(['dummy@email.com'])
      blast = create(:blast, list: create(:list), push: push, emails: [email])
      push.stub(:has_pending_jobs?).and_return(true)
      helper.can_send(blast).should == "<div class='blocked'><p>This blast can't be sent right now - check that the other blasts have finished first.</p></div>"
    end

    it "should display in-progress message when blast is in progress" do
      push = create(:push)
      email = create(:proofed_email)
      blast = create(:blast, id:99, list: create(:list), push: push, emails: [email])
      blast.stub(:has_pending_jobs?).and_return(true)
      blast.stub(:remaining_time_for_existing_jobs).and_return(99)
      notice = helper.can_send(blast)
      notice.should match('class="in-progress"')
      notice.should match('class="countdown"')
      notice.should match('99')
      notice.should match('refresh')
      notice.should match('class="reload-page"')
      notice.should match('class="js-undo-link" rel="nofollow" data-method="POST" href="/admin/blasts/99/cancel"')
      notice.should match('undo')
    end

    it "should return nil if there are no notices to display" do
      push = create(:push)
      email = create(:proofed_email)
      blast = create(:blast, list: create(:list), push: push, emails: [email])
      helper.can_send(blast).should be_nil
    end
  end
end
