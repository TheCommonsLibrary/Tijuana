function validateMPLookup(formId) {
  $('label.step-label').siblings('#user_email').width('98%');

  $(formId).validate({
    rules: {
      'mp[postcode]': { required: true, number: true },
      target_option: { required: true },
      fallback_option: { required: true }
    },
    messages: {
      'mp[postcode]': { required: 'Please enter a valid postcode.', number: 'Please enter a valid postcode.' },
      target_option: { required: 'Please select an MP.' },
      fallback_option: { required: 'Please select a Senator.' }
    },
    errorPlacement: function(error, element) {
      if($(element).attr('name') == 'target_option' || $(element).attr('name') == 'fallback_option') {
        $(element).parent().before(error);
      } else {
        $(element).before(error);
      }
    }
  });
}