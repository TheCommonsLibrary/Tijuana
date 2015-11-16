var tijuana = tijuana || {};

tijuana.donationButtons = function($donationButtons, $otherButton) {
  function assertElements() {
    if ($otherButton.find("input").length !== 2) { throw 'Expected to have 2 inputs in the other button container'; }
    if ($otherButton.find("label").length !== 1) { throw 'Expected to have 1 label in the other button container'; }
  }
  if (tijuana.isTestEnvironment()) { assertElements(); }

  var $customAmountInput = $donationButtons.find("#custom_amount_in_dollars");
  var $customAmountRadioButton = $donationButtons.find("#upgrade_amount_in_dollars_other");
  var $standardAmountButtons = $donationButtons.find(".amount-buttons").not("#other-amount");

  $customAmountRadioButton.click(function(){
    $customAmountInput.focus();
  });

  $customAmountInput.focus(function(){
    $customAmountRadioButton.prop("checked", true);
  });

  $standardAmountButtons.click(function(){
    $customAmountInput.val("");
  });

};
