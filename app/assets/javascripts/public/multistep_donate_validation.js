var tijuana = tijuana || {};

tijuana.enableMultistepDonationValidation = function(donationForm){
  var customAmountInDollar = donationForm.find('input[name="donation[custom_amount_in_dollars]"]');

  window.ParsleyValidator.addValidator('creditCardExpiry', function() {
    var chosenMonth = donationForm.find('#donation_card_expiry_month').val();
    var chosenYear = donationForm.find('#donation_card_expiry_year').val();
    if (chosenMonth !=="" && chosenYear !=="") {
      return $.payment.validateCardExpiry(chosenMonth, chosenYear);
    }

    return false;
  }, 513); // priority: must be higher than 512, Parsley's default for "required" validations

  window.ParsleyValidator.addValidator('amounts', function() {
    var AMOUNT_REG_EX = /^\s*\$?[\d]+(\.[\d]+){0,1}\s*$/;

    function otherAmountIsSelected() {
      return donationForm.find('input[name="donation[amount_in_dollars]"]:checked').attr('data-amount') === "other";
    }

    if(otherAmountIsSelected()) {
      return !!customAmountInDollar.val().match(AMOUNT_REG_EX);
    }
    return true;
  });

  window.ParsleyValidator.addValidator('phoneNumber', function(value) {
    var PHONE_NUMBER_REGEX = /^[0-9\+\(\)\.\-\_ ]+$/;
    if(value.match(PHONE_NUMBER_REGEX)) {
      return true;
    }

    return false;
  });
  
  window.ParsleyValidator.addValidator('cvv', function(cvvNumber) {
    return $.payment.validateCardCVC(cvvNumber);
  });
  
  window.ParsleyValidator.addValidator('luhn', function devCallback(val) {
    if (val === '1' || val === '2') {
      return true;
    }
    return $.payment.validateCardNumber(val);
  });
  
  var enableParsleyValidation = function(){
    donationForm.attr('data-parsley-validate', '');
    ignoreEmailsForUserLookup();
  };

  var ignoreEmailsForUserLookup = function () {
    donationForm.attr('data-parsley-excluded', 'input[type=email]');
  };

  var removeOldJqueryValidationClass = function() {
    // don't want to cause complications with parsley
    donationForm.find('.required').removeClass('required');
  };

  var enableAmountValidation = function(){
    customAmountInDollar.attr('data-parsley-group', 'step1');
    customAmountInDollar.attr('data-parsley-amounts', '');
    customAmountInDollar.attr('data-parsley-amounts-message', 'Please enter a valid amount');
    customAmountInDollar.attr('data-parsley-required-message', 'Please enter a valid amount');
    customAmountInDollar.attr('data-parsley-errors-container', '.donation');
  };

  var enableUserDetailsValidation = function(userDetails){
    function needsValidation(field, data) {
      if (data.user === undefined) {
        return false;
      }

      var fieldName = field.data('user-field');
      var visible = data.user[fieldName];
      var required = field.prev('label').text().indexOf('*') >= 0;

      return required && visible;
    }

    function addValidationForNumber(field, displayName) {
      if (displayName === 'Mobile Number' || displayName === 'Home Number') {
        field.attr('data-parsley-phoneNumber', '');
      } else {
        field.attr('data-parsley-type', 'number');
        field.attr('data-parsley-type-message', "Should be a valid number");
      }
    }

    function rebindParleyValidation() {
      donationForm.parsley().destroy();
      donationForm.parsley();
    }

    function addValidationForUserSpecificDetails(){
      var userSpecificDetails = userDetails.find('#ask-specific-user-details');
      userSpecificDetails.find('input').attr('data-parsley-group', 'step2');

      window.LookupUserEvent.subscribe(function(data) {

        // If the user's address is required, ensure that labels for address
        // fields have an asterix. The presence of the asterix is actually used
        // to determine if the parsley validation should be applied.
        if (data.address_required){
          $.each(['street_address', 'suburb', 'postcode_number', 'country_iso'], function(index, field){
            var $label = $('label[for=user_'+field+']');
            if ($label.text().indexOf('*') === -1){
              $label.text($label.text() + '*');
            }
          });
        }

        userSpecificDetails.find('.user-field').each(function (_, elem) {
          var field = $(elem);
          field.attr('data-parsley-trigger', 'blur');

          if (needsValidation(field, data)) {
            var displayName = field.attr('placeholder');
            field.attr('data-parsley-required', true);
            field.attr('data-parsley-required-message', displayName + " can't be blank");
            if (displayName && (displayName.indexOf('Number') > -1) ){ addValidationForNumber(field, displayName); }
          } else {
            field.attr('data-parsley-required', false);
          }
        });

        rebindParleyValidation();

      });
    }

    addValidationForUserSpecificDetails();
  };

  var enablePaymentValidation = function(paymentDetails){
    var donationCardNumber = paymentDetails.find('#donation_card_number');
    var donationNameOnCard = paymentDetails.find('#donation_name_on_card');
    var donationCardExpiryMonth = paymentDetails.find('#donation_card_expiry_month');
    var donationCardExpiryYear = paymentDetails.find('#donation_card_expiry_year');
    var donationCardCVV = paymentDetails.find('#donation_card_cvv');

    function addGroupAndRequiredAttr() {
      var allInputFields = paymentDetails.find('input[type=text], input[type=tel], select');
      allInputFields.each(function (_, elem) {
        var field = $(elem);
        field.attr('data-parsley-group', 'step3');
        field.attr('data-parsley-required', true);
      });
    }

    function addCreditCardNumberValidation(field) {
      field.payment('formatCardNumber');
      field.attr('data-parsley-luhn', '');
      field.attr('data-parsley-luhn-message', "This doesn't appear to be a valid card number.");
      field.attr('data-parsley-required-message', "Card Number can't be blank.");
      field.attr('data-parsley-trigger', 'change');
    }

    function addCardExpiryValidation(field) {
      field.attr("data-parsley-creditCardExpiry", "");
      field.attr("data-parsley-creditCardExpiry-message", "Please enter a valid expiry date.");
      field.attr('data-parsley-multiple', 'cardexpiry');
    }

    function addCvvValidation(field) {
      field.attr("data-parsley-cvv", "");
      field.attr("data-parsley-cvv-message", "Security Code is invalid.");
      field.attr("data-parsley-required-message", "Security Code can't be blank.");
      field.attr('data-parsley-trigger', 'change');
    }

    function addNameOnCardValidation(field) {
      field.attr("data-parsley-required-message", "Name on Card can't be blank.");
      field.attr('data-parsley-trigger', 'change');
    }

    addGroupAndRequiredAttr();
    addCreditCardNumberValidation(donationCardNumber);
    addNameOnCardValidation(donationNameOnCard);
    addCardExpiryValidation(donationCardExpiryMonth, "month");
    addCardExpiryValidation(donationCardExpiryYear, "year");
    donationCardExpiryMonth.attr('data-parsley-errors-messages-disabled', true);
    addCvvValidation(donationCardCVV);
  };

  removeOldJqueryValidationClass();
  enableParsleyValidation();
  enableAmountValidation(donationForm.find('#step-1-amount'));
  enableUserDetailsValidation(donationForm.find('#step-2-name'));
  enablePaymentValidation(donationForm.find('#step-3-payment'));
};
