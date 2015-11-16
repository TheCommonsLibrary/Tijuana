describe "Record testimonials", ->

  # FB sdk doesn't seem to load in phantomjs. Have tried passing command line
  # arguments. Adding an onload handler seems to suggest that it doesn't get
  # loaded. Taking too much time to debug so commenting out of phantomjs for now.
  return if window._phantom

  beforeEach ->
    setFixtures "<div class='content'> </div> <div id='fb-root'> </div> <div class='fb-comments'> </div>"

  describe "leaving a testimonial", ->
    it "posts the correct data when comment create event is fired", (done) -> 
      configureTestimonialModule(1, 'a', 2, 3)
      $(document).on 'fb-load', ->
        comment = "This mine and port  is a lose lose combination of unthinking ideology and corruption of government by vested interest.\n\nIt will NOT employ many people - less than 1500  jobs as opposed to 10000 promised by Adani.\nIt will NOT generate much tax revenue. Adani Australia will profit shift to Adani India.\nIt WILL increase world coal supply and reduce price, in spite of what mr turnbull says. It will increase world co2 emissions at a time when Australia should be leading the charge to reduce emissions. \nIt is in Indias best interests to develop renewable eleictricity system. Renewable energy requires less distribution cost and reduces indias dependency on importedd fuel. Availabity of thermal coal will deter the Indians from following this path. It benefits only vested interests in india. \nIt will damage our food production capacity both on land and on the water\nIt will damage our tourism industry\nIt will damage the barrier reef \n\nAdani has a track record of breaking promises, failing to adhere to environment requirements and breaking environmental law . yet this government has entrusted them with our world heritage area, which is our duty to protect."
        sinon.stub $, 'post', ->
          call = $.post.getCall(0)
          expect(call.args).toEqual(['/testimonial/record_action', {'facebook_id': '100000255545522', 'module_id': 1, 't': 'a', 'app_id': 2, 'page_id': 3, 'testimonial_text': comment }])
          done()
        # XXX Assumes that this page exists on production and that the comment with this ID is a recent comment
        window.commentCreateSubscribe {href: 'https://www.getup.org.au/campaigns/great-barrier-reef--3/adani-is-back-ask/urgent-help-us-fight-adani-in-court-again', commentID: '1034463229939664_1047512811968039'}

