describe "emailFormValidation", ->
  beforeEach ->
    setFixtures "
      <form>
        <input id='user_email_subject' value='test' />
        <textarea id='user_email_body'>test</textarea>
      </form>
    "
  
  it "should error when subject missing and preconfigured values are placeholders only", ->
    $("form").find("#user_email_subject").val ""
    $("form").attachAlertValidation emailFormValidation(placeholders: true)
    $("form").trigger "runValidation"
    expect($("form").data "error").toBe "A subject is required"
    
  it "should error when body missing and preconfigured values are placeholders only", ->
    $("form").find("#user_email_body").val ""
    $("form").attachAlertValidation emailFormValidation(placeholders: true)
    $("form").trigger "runValidation"
    expect($("form").data "error").toBe "A message is required"
    
  it "should warn when subject or body missing and preconfigured values are default text", ->
    $("form").find("#user_email_subject").val ""
    $("form").attachAlertValidation emailFormValidation(placeholders: false)
    $("form").trigger "runValidation"
    expect($("form").data "warning").toBe "You have entered a blank subject or message, would you like to send the defaults?"