describe "donation buttons component", ->
  beforeEach ->
    setFixtures """
      <div id="donation-buttons">
        <div class="amount-buttons">
          <input id="upgrade_amount_in_dollars_5" name="upgrade_amount_in_dollars" type="radio" value="5">
          <label for="upgrade_amount_in_dollars_5">+$5</label>
        </div>
        <div class="amount-buttons" id="other-amount">
          <input id="upgrade_amount_in_dollars_other" name="upgrade_amount_in_dollars" type="radio" value="other">
          <label for="upgrade_amount_in_dollars_other">+$</label>
          <input id="custom_amount_in_dollars" name="custom_amount_in_dollars" placeholder="Other" type="tel" value="">
        </div>
      </div>
    """
    @buttons = $("#donation-buttons")
    @other = @buttons.find("#other-amount")
    @otherRadioButton = @other.find("#upgrade_amount_in_dollars_other")
    @otherNumInput = @other.find("#custom_amount_in_dollars")
    tijuana.donationButtons(@buttons, @other)
    @five = $("#donation-buttons").children().first()

  it "focusses on num input when 'other' radio button selected", ->
    @otherRadioButton.click()
    expect(@otherNumInput).toBeFocused()

  it "selects the 'other' radio button when the num input is focussed", ->
    @otherNumInput.focus()
    expect(@otherRadioButton).toBeChecked()

  it "clears the num input when any non-'other' radio button is selected", ->
    @otherNumInput.val("123")
    expect(@otherNumInput.val()).toBe "123"
    @otherRadioButton.click()
    expect(@otherNumInput.val()).toBe "123"
    @five.click()
    expect(@otherNumInput.val()).toBe ""
