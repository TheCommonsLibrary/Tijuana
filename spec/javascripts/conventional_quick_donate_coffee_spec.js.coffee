describe "conventional quick donate", ->
  beforeEach ->
    loadFixtures "conventional_quick_donate_form.html"
    @form = $("#action-form")
    @creditTab = @form.find("#credit")
    @resetLink = @form.find(".reset-quick-donate")
    @invitation = @form.find(".invitation")
    @quickDonateForm = @form.find(".quick-donate-form")
    tijuana.enableConventionalQuickDonateLogout(@form)

  it "log out of quick donate when click on 'Wrong name or card? Click here to reset' link", ->
    @resetLink.click()
    expect(@creditTab).toHaveClass "active"
    expect(@invitation).toHaveCss {display: "block"}
    expect(@quickDonateForm).toHaveCss {display: "none"}
