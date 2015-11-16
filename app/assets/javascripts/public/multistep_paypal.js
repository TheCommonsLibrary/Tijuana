var tijuana = tijuana || {};

tijuana.enableMultiStepPaypal = function(paypalLink, paypalForm, donationFormController) {

  function convertToPaypalFrequencyCode(frequency) {
    switch (frequency) {
      case 'weekly':
        return 'W';
      case 'monthly':
        return 'M';
      case 'annual':
        return 'Y';
      default:
        return null;
    }
  }

  function appendHiddenField(name, value) {
    paypalForm.append("<input type='hidden' name='" + name + "' value='" + value + "'>");
  }

  function replaceWithHiddenField(name, value) {
    paypalForm.find('input[name="' + name + '"]').replaceWith("<input type='hidden' name='" + name + "' value='" + value + "'>");
  }

  function setRecurringForm(amount, frequency) {
    replaceWithHiddenField('cmd', '_xclick-subscriptions');
    appendHiddenField('sra', '1');
    appendHiddenField('src', '1');
    appendHiddenField('a3', amount);
    appendHiddenField('p3', '1');
    appendHiddenField('t3', convertToPaypalFrequencyCode(frequency));
  }

  function setOneOffForm(amount) {
    appendHiddenField('amount', amount);
  }

  function setRecurringOrOneOffForm(amount) {
    var frequency = donationFormController.frequency();
    var recurring = frequency && frequency !== "one_off";
    if (recurring) {
      setRecurringForm(amount, frequency);
    } else {
      setOneOffForm(amount);
    }
  }

  function linkClicked(event) {
    event.preventDefault();

    if (donationFormController.validateStep(1)) {
      var amount = donationFormController.amount();
      $(this).text('Loading PayPal..');
      setRecurringOrOneOffForm(amount);
      paypalForm.submit();
    }
  }

  paypalLink.click(linkClicked);
};
