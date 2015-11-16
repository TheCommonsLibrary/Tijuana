var tijuana = tijuana || {};

tijuana.enableQuickDonate = function(donationForm, donationFormProperties) {
    var quickDonate = donationForm.find("#quick-donate");
    var quickDonateReset = donationForm.find(".not-you a");
    var paymentButton = donationForm.find(".btn-payment");
    var validationRequiredFields = donationForm.find('[data-parsley-required="true"]');
    var quickDonateFlag = donationForm.find("#donation_quick_donation");
    var paymentTab = donationForm.find("#step-3-payment");

    function clearPaymentInfo() {
      allPaymentInfo = paymentTab.find("input, select");
      allPaymentInfo.each( function() {
        $(this).val("");
      });
    }

    function unsetQuickDonate() {
      tijuana.logoutQuickDonate();
      clearPaymentInfo();
      quickDonate.remove();
      $('.donate-well').removeClass('quick-donate-enabled');
      $('.donate-well').addClass('quick-donate-disabled');
      validationRequiredFields.attr('data-parsley-required', true);
      donationForm.removeAttr('data-disable-user-lookup');
      quickDonateFlag.val('');
    }

    quickDonateReset.click(function(e) {
      unsetQuickDonate();
      e.preventDefault();
    });

    function setupQuickDonate() {
      if (quickDonate.length) {
        $('.donate-well').removeClass('quick-donate-disabled');
        $('.donate-well').addClass('quick-donate-enabled');
        validationRequiredFields.attr('data-parsley-required', false);
        donationForm.attr('data-disable-user-lookup', true);
        quickDonateFlag.val('1');
      }
    }

  setupQuickDonate();
};
