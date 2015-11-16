describe "multistep donate", ->
  beforeEach ->
    loadFixtures "multistep_donation_form.html"
    @form = $("#action-form")
    @screenNav = $(".screen-nav")
    @tab1 = @screenNav.find("a[data-step=1]")
    @tab2 = @screenNav.find("a[data-step=2]")
    @tab3 = @screenNav.find("a[data-step=3]")
    @screen2 = @form.find(".screen[data-step=2]")
    @screen3 = @form.find(".screen[data-step=3]")
    @emailField = @form.find("#user_email")
    @cardNumberField = @form.find("#donation_card_number")
    @paymentButton = @form.find('.btn-payment')
    @otherAmount = @form.find(".otheramount")
    @lookupUserController =
      forceLookup: ->
      isCompleted: ->
    
  stubParsleyValidateToReturn = (isValid) ->
    ->
      parsley = validate: ->
      spyOn(@form, "parsley").and.returnValue parsley
      spyOn(parsley, "validate").and.returnValue isValid

  hitKeyOnForm = (key) ->
    ->
      keyDownEvent = $.Event("keypress")
      keyDownEvent.keyCode = key
      @form.trigger keyDownEvent

  describe "user lookup integration", ->
    beforeEach ->
      tijuana.multiStepDonationForm(@form, @screenNav, false, @lookupUserController)
      @tab2.click()
    beforeEach stubParsleyValidateToReturn(true)
    
    describe "forcing lookup", ->
      it "when force lookup allows us to continue we will move to the next step", ->
        sinon.stub(@lookupUserController, 'forceLookup').callsArg(0)
        @tab3.click()
        expect(@tab3).toHaveClass('active')
      
      it "when force lookup does not allow us to continue (doesn't call callback) we will stay on the same step", ->
        sinon.stub(@lookupUserController, 'forceLookup').returns(null)
        @tab3.click()
        expect(@tab2).toHaveClass('active')
      
    describe "lookup user complete", ->
      beforeEach ->
        @form.submit (e) -> e.preventDefault()
        sinon.stub(@lookupUserController, 'forceLookup').callsArg(0)
        @tab3.click()
        
      it "when lookup user is complete then you can submit the form", ->
        sinon.stub(@lookupUserController, 'isCompleted').returns(true)
        @paymentButton.click()
        expect($('.processing')).toBeVisible()
        
      it "when lookup user is not complete then you can not submit the form", ->
        sinon.stub(@lookupUserController, 'isCompleted').returns(false)
        @paymentButton.click()
        expect($('.processing')).not.toBeVisible()

  describe "when the enter key is pressed in the form and with the form in multistep form mode", ->
    beforeEach ->
      tijuana.multiStepDonationForm(@form, @screenNav)

    describe "with the step being valid", ->
      beforeEach stubParsleyValidateToReturn(true)
      beforeEach hitKeyOnForm(13)
      it "should move to the next step", ->
        expect(@tab2).toHaveClass("active")

    describe "with the current step being invalid", ->
      beforeEach stubParsleyValidateToReturn(false)
      beforeEach hitKeyOnForm(13)
      it "should NOT move to the next step", ->
        expect(@tab1).toHaveClass("active")

  describe "server side validation errors", ->
    beforeEach ->
      @form.append "<div class=\"alert alert-error\"><ul><li>it broke!</li></ul></div>"

    it "should display step 2 when user details validation errors", ->
      tijuana.multiStepDonationForm(@form, @screenNav, true)
      expect(@tab2).toHaveClass "active"
      expect(@screen2).not.toHaveClass "hide-in-multistep"

    it "should display step 3 when not user details validation errors", ->
      tijuana.multiStepDonationForm(@form, @screenNav, false)
      expect(@tab3).toHaveClass "active"
      expect(@screen3).not.toHaveClass "hide-in-multistep"

  describe "should focus on first input element", ->
    beforeEach ->
      sinon.stub(@lookupUserController, 'forceLookup').callsArg(0)
      tijuana.multiStepDonationForm(@form, @screenNav, false, @lookupUserController)

    it "focus on email field when 'Next' button was clicked on first step", ->
      @tab2.click()
      expect(@emailField).toBeFocused()

    it "focus on credit card number field when 'Next' button was clicked on second step", ->
      @tab2.click()
      @tab3.click()
      expect(@cardNumberField).toBeFocused()

  describe "should not focus on other amount", ->
    beforeEach ->
      tijuana.multiStepDonationForm(@form, @screenNav, false, @lookupUserController)

    it "when going back from step 2", ->
      @tab2.click()
      @tab1.click()
      expect(@otherAmount).not.toBeFocused()
