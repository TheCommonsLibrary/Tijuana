function donationUpgrade(paymentBtnSelector, customInputSelector) {
  var $paymentButton = $(paymentBtnSelector),
        $customInput = $(customInputSelector)[0],
        amountRegex = /^\$?[\d]+(\.[\d]+){0,1}$/;

  function updateAmount(amount){ $paymentButton.text('Increase by $' + amount); }
  updateAmount($('.amount-buttons input:checked').val());

  function standardUpdate(event){ updateAmount(event.target.value); }
  $('#donation-buttons').find('.amount-buttons').not('#other-amount').change(standardUpdate);

  function customUpdate(){
    var amount = $customInput.value;
    if ((amount !== '') && (amountRegex.test(amount) === true)) { updateAmount(amount); }
  }
  $('#other-amount').keyup(customUpdate);
}
