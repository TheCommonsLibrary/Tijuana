describe "Lookup User", ->
  beforeEach ->
    loadFixtures "user_lookup.html"
    @emailField = $("#user_email")
    @lookupUserParams = [
      "/users/lookup", "page_id", 123,
      "#user_email", "#ask-specific-user-details",
      "label[for=\"become-member-checkbox\"]", true
    ]

  describe "behaviour", ->
    beforeEach ->
      @ajaxStub = sinon.stub $, "ajax"
      lookupUser(@lookupUserParams...)

    afterEach ->
      $.ajax.restore()

    it "fires when email address field blurs", ->
      @emailField.val("email@example.com").blur()
      expect(@ajaxStub.calledOnce).toBe(true)

    it "displays an error if the email address is missing and the form is submitted", ->
      @emailField.parents("form").submit()
      expect($(".user-lookup-message .alert-error")).toExist()

    describe "(with a short delay)", ->
      beforeEach ->
        jasmine.clock().install()
        @AJAX_DELAY = 1400

      afterEach ->
        jasmine.clock().uninstall()

      it "fires when a keydown happens in email address field", ->
        @emailField.val("email@example.com").keydown()
        jasmine.clock().tick(@AJAX_DELAY)
        expect(@ajaxStub.calledOnce).toBe(true)

      it "displays a prompt if the email address is invalid", ->
        @emailField.val("test").keydown()
        jasmine.clock().tick(@AJAX_DELAY)
        expect($(".user-lookup-message").html()).toBe("Hmm... Your email looks incomplete?")

  describe "public interface", ->
    beforeEach ->
      @lookupUserController = lookupUser(@lookupUserParams...)
      @callback = sinon.spy()
      @server = sinon.fakeServer.create()
      makeFormAutoSubmittable()

    afterEach ->
      @server.restore()

    makeFormAutoSubmittable = -> $("#action-form").addClass("auto-submittable")
    mockLookupUser = ({detailsRequired}) ->
      ->
        @server.respondWith [
          200, { "Content-Type": "application/json" }
          "{\"user\": {\"needs_more_details\": #{detailsRequired}}}"
        ]
        @emailField.val("email@example.com")
        @lookupUserController.forceLookup(@callback)
        @server.respond()

    describe "#forceLookup", ->
      describe "when xhr call says the server requires more details", ->
        beforeEach mockLookupUser(detailsRequired: true)
        it "should NOT call the passed callback", ->
          expect(@callback.calledOnce).toBe(false)

      describe "when xhr call says the server does NOT require more details", ->
        beforeEach mockLookupUser(detailsRequired: false)
        it "should call the passed callback", ->
          expect(@callback.calledOnce).toBe(true)

    describe "#isCompleted", ->
      describe "before any action is taken", ->
        it "should be false", ->
          expect(@lookupUserController.isCompleted()).toBe(false)

      describe "after lookupUser has succesfully run", ->
        beforeEach mockLookupUser(detailsRequired: false)
        it "should be true", ->
          expect(@lookupUserController.isCompleted()).toBe(true)
