describe "attachAlertValidation", ->
  boomValidation = ->
    $(this).data("error", "boom!")
  
  allGoodValidation = ->
    
  sureWarning = ->
    $(this).data("warning", "are you sure?")
    
  beforeEach ->
    setFixtures "<div id='form'></div>"
  
  it "should alert and not submit if validation errors", ->
    spyOn window, 'alert'
    $("#form").attachAlertValidation boomValidation
    valid = $("#form").triggerHandler("submit")
    expect(window.alert).toHaveBeenCalledWith "boom!"
    expect(valid).toBe false
    
  it "should not alert and should do submission if all good", ->
    spyOn window, 'alert'
    $("#form").attachAlertValidation allGoodValidation
    valid = $("#form").triggerHandler("submit")
    expect(window.alert).not.toHaveBeenCalled()
    expect(valid).toBe true
    
  it "should warn and submit only on confirmation", ->
    spyOn(window, 'confirm').and.returnValue true
    $("#form").attachAlertValidation sureWarning
    valid = $("#form").triggerHandler("submit")
    expect(window.confirm).toHaveBeenCalled()
    expect(valid).toBe true
    
  it "should warn and not submit if confirmation cancelled", ->
    spyOn(window, 'confirm').and.returnValue false
    $("#form").attachAlertValidation sureWarning
    valid = $("#form").triggerHandler("submit")
    expect(window.confirm).toHaveBeenCalled()
    expect(valid).toBe false