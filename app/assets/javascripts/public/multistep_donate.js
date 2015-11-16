var tijuana = tijuana || {};

/*jshint -W032 */
tijuana.multiStepDonationForm = function(donationForm, screenNav, userDetailsError, lookupUserController, emergencyPaypalEnabled) {
  var customAmountInDollar = donationForm.find('input[name="donation[custom_amount_in_dollars]"]');
  var AMOUNT_REG_EX = /^\$?[\d]+(\.[\d]+){0,1}$/;
  
  function assertElements() {
    if (screenNav.find('a[data-step]').length !== 3) { throw 'Expected to have 3 wizard steps in the top navigation'; }
    if (donationForm.find('.screen[data-step]').length !== 3) { throw 'Expected to have 3 wizard screens in the form'; }
    if (donationForm.find('.other-radio').length !== 1) { throw 'Expected to have an other radio button'; }
    if (donationForm.find('input.payment-input[type=radio][name="donation[amount_in_dollars]"]').length === 0) { throw 'Expected to have donation amount radio buttons'; }
    if (donationForm.find('.donation .btn[data-amount]').length === 0) { throw 'Expected to have donation amount buttons'; }
    if (donationForm.find(".btn-next").length === 0) { throw 'Expected to have next buttons'; }
    if (donationForm.find('#donation_card_number').length !== 1) { throw 'Expected to have a credit card number field'; }
    if (donationForm.find('label.cvv').length !== 1) { throw 'Expected to have a cvv label'; }
    if (donationForm.find('.card-types img').length === 0) { throw 'Expected to have card type images'; }
    if (donationForm.find('.processing').length !== 1) { throw 'Expected to have a processing div'; }
    if (donationForm.find(".btn-payment").length !== 1) { throw 'Expected to have a payment button'; }
    if (donationForm.find(".otheramount").length !== 1) { throw 'Expected to have a other amount field'; }
  }

  function detectInternetExplorerProperly() {
    var ua = window.navigator.userAgent;
    var msie = ua.indexOf("MSIE ");
    if (msie > 0 || !!navigator.userAgent.match(/Trident.*rv\:11\./)) {
      if (!$('html').hasClass('ie')) {
        $('html').addClass('ie');
      } 
    }
  }

  function isMultiStepDisplayed() { return screenNav.is(':visible'); }
  function getCurrentStep(){ return parseInt(screenNav.find('.active').data('step'), 10); }

  function showStep(num) {
    screenNav.find('a[data-step]').removeClass('active');
    screenNav.find('a[data-step="' + num + '"]').addClass('active');
    donationForm.find('.screen[data-step]').addClass('hide-in-multistep');
    donationForm.find('.screen[data-step="' + num + '"]').removeClass('hide-in-multistep');
    if (num !== 1) {
      donationForm.find('.screen[data-step="' + num + '"]').find("input").first().focus();
    }
  }

  function validateStep(num) {
    var valid = donationForm.parsley().validate('step' + num);
    return valid;
  }

  function gotoNextStepIfValid(gotoStep){
    var currentStep = getCurrentStep();
    if (gotoStep > currentStep) {
      if (gotoStep - currentStep > 1) { return false; }
      if (!validateStep(currentStep)) { return false; }
    }
    if (currentStep === 2) {
      lookupUserController.forceLookup(function(){ showStep(gotoStep); });
    } else {
      showStep(gotoStep);
    }
  }
  
  function augmentErrorList() {
    var errorList = donationForm.find('.alert.alert-error ul');
    var augmentedMessage = errorList.html()
      .replace('please donate with Paypal', 'please <a href="javascript:$(\'.paypal-donation\').click();">donate with Paypal</a>')
      .replace('donations@getup.org.au','<a href="mailto:donations@getup.org.au">donations@getup.org.au</a>')
      .replace('(02) 8188 2888','<a href="tel:+61281882888">(02) 8188 2888</a>');
    errorList.html(augmentedMessage);
  }

  var showServerErrorMessageIfAny = function() {
    function serverValidationErrorsPresent() { return donationForm.find('.alert-error').length; }

    if (isMultiStepDisplayed() && serverValidationErrorsPresent()) {
      if (userDetailsError) {
        showStep(2);
      }else {
        augmentErrorList();
        showStep(3);
      }
    }
  };

  // TODO: candidate for its own file
  var hookupDonationAmounts = function () {
    function isOtherAmountSelected() { return donationForm.find('.other-radio').prop('checked'); }
    
    function setSelectedAmountButtonFromFormData() {
      var $formDataAmount = donationForm.find('input[name="donation[amount_in_dollars]"]:checked');
      if ($formDataAmount.length){
        donationForm.find('.btn[data-amount=' + $formDataAmount.data('amount') + ']').trigger('click');
      }
    }

    function isValidDonationAmount(donationAmount) {
      if ((donationAmount !== '') && (AMOUNT_REG_EX.test(donationAmount) === true)) {
        return true;
      }
      return false;
    }

    function appendToDonateButtonText(amount) {
      if (isValidDonationAmount(amount)) {
        donationForm.find(".btn-payment").text('DONATE $' + amount.toString().replace('$', ''));
      } else {
        donationForm.find(".btn-payment").text('DONATE');
      }
    }

    function deselectOtherAmountButton() {
      customAmountInDollar.removeAttr('data-parsley-required');
      customAmountInDollar.val('');
      // Force validation to clear the parsley message
      validateStep(1);
    }

    function highlightSelectedDonationAmountButton(selectedButton) {
      donationForm.find('.donation .btn.active, label[for=donation_custom_amount_in_dollars]').removeClass('active');
      if (selectedButton.is('.btn')) {
        selectedButton.addClass('active');
      }else{
        donationForm.find('label[for=donation_custom_amount_in_dollars]').addClass('active');
      }
    }

    function selectRadioButtonOf(donationAmount) {
      var $radio = donationForm.find('input[type=radio][data-amount=' + donationAmount + ']');
      $radio.prop('checked', true).trigger("change");
    }

    function refreshOtherAmountControls() {
      if (isOtherAmountSelected()) {
        customAmountInDollar.attr('data-parsley-required', true);
      } else {
        deselectOtherAmountButton();
      }
    }

    function hookUpCustomAmountChangeToUpdateDonateButtonWithAmount() {
      customAmountInDollar.on('change paste keyup', function() {
        var customAmount = customAmountInDollar.val().trim();
        appendToDonateButtonText(customAmount);
      });
    }
    
    function amountActivated(event) {
      var $clickedButton = $(event.currentTarget);
      highlightSelectedDonationAmountButton($clickedButton);
      var amount = $clickedButton.data('amount');
      selectRadioButtonOf(amount);
      refreshOtherAmountControls();
      appendToDonateButtonText(amount);
    }
    
    function moveOtherAmountIntoButtonGrid() {
      donationForm.find('.other-prepend').appendTo(donationForm.find('.button-amount-fields'));
    }

    function selectAmountBasedFromParam() {
      var query = window.location.search;
      var match, amount, $button;
      if (query && (match = query.match(/[&\?]a=(\d+)/))) {
        amount = match[1];
        $button = $('button.btn[data-amount=' + amount + ']');
        if ($button.length) {
          amountActivated({currentTarget: $button[0]});
        } else {
          // populate 'other amount'
          $(".otheramount").val(amount);
          amountActivated({currentTarget: donationForm.find('.js-amount-other')});
          appendToDonateButtonText(amount);
        }

      }
    }
    
    donationForm.find('.donation .btn, .js-amount-other').focus(amountActivated);
    donationForm.find('.donation .btn, .js-amount-other').click(amountActivated);
    donationForm.find('.js-amount-other').keypress(function(){
      var amount = $(this).data('amount');
      appendToDonateButtonText(amount);
    });
    hookUpCustomAmountChangeToUpdateDonateButtonWithAmount();
    setSelectedAmountButtonFromFormData();
    moveOtherAmountIntoButtonGrid();
    selectAmountBasedFromParam();
  };

  var hookupNavigationLinkToGoToStep = function () {
    screenNav.find('a').click( function(e) {
      e.preventDefault();
      gotoNextStepIfValid(parseInt($(this).data('step'), 10));
    });
  };

  var hookupNextButtonsToGoToNextStep = function () {
    donationForm.find(".btn-next").click( function(e) {
      e.preventDefault();
      gotoNextStepIfValid(parseInt($(this).data('step'), 10));
    });
  };

  var hookupEnterToGoToNextStep = function () {
    donationForm.keypress(function(e) {
      if (e.keyCode === 13 && isMultiStepDisplayed()) {
        var currentStep = getCurrentStep();
        if (currentStep < 3){
          e.preventDefault();
          gotoNextStepIfValid(currentStep + 1);
        }
      }
    });
  };

  var indicateCardTypeFromCardNumber = function () {
    var donationCardNumber = donationForm.find('#donation_card_number');

    function populateCvvTooltipFor(cardType) { donationForm.find('label.cvv').attr('data-card', cardType); }
    
    function unhighlightCreditCardImages() {
      donationForm.find('.card-types img').addClass('inactive').removeClass('current');
    }

    function highlightCreditCardImageFor(cardType) {
      if (donationForm.find('.card-types .' + cardType).length > 0) {
        donationForm.find('.card-types img').removeClass('inactive');
        donationForm.find('.card-types .' + cardType).addClass('current');
        donationForm.find('.card-types :not(.' + cardType + ')').addClass('inactive');
      }
    }

    function getCreditCardType(cardNumber) {
      var type = $.payment.cardType(cardNumber);
      if (type === 'amex') { type = 'american_express'; }
      return type;
    }

    unhighlightCreditCardImages();
    donationCardNumber.on('change keyup paste focus', function() {
      unhighlightCreditCardImages();
      var cardType = getCreditCardType(donationCardNumber.val());
      highlightCreditCardImageFor(cardType);
      populateCvvTooltipFor(cardType);
    });
  };
  
  var hookupDonateButtonToSubmitForm = function () {
    function isQuickDonateEnabled() { return (donationForm.find("#donation_quick_donation").val() === '1'); }

    function finalValidation() {
      var formValid = donationForm.parsley().validate();
      return (isQuickDonateEnabled() || lookupUserController.isCompleted()) && formValid;
    }

    donationForm.submit(function(e) {
      if (finalValidation()) {
        donationForm.find('.alert-error').hide();
        donationForm.find('.processing').fadeIn('fast');
      } else {
        e.preventDefault();
      }
    });
  };

  function setupEmergencyPaypal() {
    var paypalLink = $('a.paypal-donation').detach();
    paypalLink.addClass("btn btn-primary-alternate btn-large btn-full btn-payment");
    $('.screen-content').append(paypalLink);
  }

  if (tijuana.isTestEnvironment()) {
    assertElements();
  }
  hookupDonateButtonToSubmitForm();
  detectInternetExplorerProperly();
  showServerErrorMessageIfAny();
  hookupDonationAmounts();
  hookupNavigationLinkToGoToStep();
  hookupNextButtonsToGoToNextStep();
  hookupEnterToGoToNextStep();
  indicateCardTypeFromCardNumber();

  if (emergencyPaypalEnabled) { setupEmergencyPaypal(); }

  return ({
    amount: function() {
      var value = donationForm.find("input.payment-input:checked").val();
      if (value === "other") {
        var raw_value = customAmountInDollar.val();
        value = /\$?([0-9\.]*)/.exec(raw_value)[1];
      }
      return value;
    },
    frequency: function() {
      return donationForm.find('#donation-frequency-credit').val();
    },
    validateStep: function(num) {
      return validateStep(num);
    }
  });
};

