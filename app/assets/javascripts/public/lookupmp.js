function lookupMP(lookupUrl, evaluatePartyUrl, selectSenatorUrl, moduleId, showSteps) {
  var postcodeField = $('#mp_postcode');
  var mpsContainer = $('#mps-lookup');
  var fallbackContainer = $('#fallback-lookup');
  var selectSenatorContainer = $('#select-senator');
  var mpOptionSelector = '.mp_option';
  var mpPhoneNumberContainer = '.mp-phone-number';
  var mpPhoneNumberSelector = 'span.phone-number';
  var fallbackOptionSelector = '.fallback_option';
  var timeoutId;
  var lastText, lastMP, lastSenator;

  function selectedSenator(data, status, xhr) {
    var $message = mpPhoneNumberDecorator.linkPhoneNumberIfTelSupported($(data).find(mpPhoneNumberContainer), mpPhoneNumberSelector);
    $(data).find(mpPhoneNumberContainer).html($message);
    selectSenatorContainer.html(data);
    $(selectSenatorContainer).find(mpPhoneNumberContainer).html($message);
    selectSenatorContainer.slideDown();
    toggleContactMpForm();
  }

  function lookedUpFallback(data, status, xhr) {
    var $message = mpPhoneNumberDecorator.linkPhoneNumberIfTelSupported($(data).find(mpPhoneNumberContainer), mpPhoneNumberSelector);
    $(data).find(mpPhoneNumberContainer).html($message);
    $(fallbackOptionSelector).unbind('change');
    fallbackContainer.html(data);
    $(fallbackContainer).find(mpPhoneNumberContainer).html($message);
    fallbackContainer.slideDown();
    $(fallbackOptionSelector).bind('change', selectSenator);
    toggleContactMpForm();
  }

  function lookedUpMP(data, status, xhr) {
    var $message = mpPhoneNumberDecorator.linkPhoneNumberIfTelSupported($(data).find(mpPhoneNumberContainer), mpPhoneNumberSelector);
    $(data).find(mpPhoneNumberContainer).html($message);
    $(mpOptionSelector).unbind('change');
    $(fallbackOptionSelector).unbind('change');
    mpsContainer.html(data);
    $(mpsContainer).find(mpPhoneNumberContainer).html($message);
    mpsContainer.slideDown();
    $(mpOptionSelector).bind('change', getFallback);
    $(fallbackOptionSelector).bind('change', selectSenator);
    toggleContactMpForm();
  }

  function getMP() {
    var currentText = postcodeField.val();
    if (currentText != lastText) {
      mpsContainer.slideUp(40).empty();
      fallbackContainer.slideUp(40).empty();
      selectSenatorContainer.slideUp(40).empty();
      $.get(lookupUrl, {postcode: postcodeField.val(), module_id: moduleId}, lookedUpMP);
      lastText = postcodeField.val();
    }
  }

  function getFallback() {
    var currentMP = $(".mp_option:radio:checked").val();
    if (currentMP != lastMP) {
      fallbackContainer.slideUp(40).empty();
      selectSenatorContainer.slideUp(40).empty();
      $.get(evaluatePartyUrl, {mp_id: currentMP, module_id: moduleId, postcode: postcodeField.val()}, lookedUpFallback);
    }
  }

  function selectSenator() {
    var currentSenator = $(".fallback_option:radio:checked").val();
    if (currentSenator != lastSenator) {
      selectSenatorContainer.slideUp(40).empty();
      $.get(selectSenatorUrl, {fallback_id: currentSenator, module_id: moduleId}, selectedSenator);
    }
  }

  function politelyLookupMP() {
    if (timeoutId !== undefined) {
      clearTimeout(timeoutId);
    }
    timeoutId = setTimeout(getMP, 750);
  }
  postcodeField.bind('keyup change', politelyLookupMP);

  function toggleContactMpForm() {
    if(showSteps) {
      if ($('#targets').length > 0) {
        $('#contact-mp-form').show();
      } else {
        $('#contact-mp-form').hide();
      }
    }
  }

  var mpPhoneNumberDecorator = (function () {
    function linkPhoneNumberIfTelSupported(container, mpPhoneNumberSelector) {
      if (isBrowserSupported()) {
        return linkPhoneNumber(container, mpPhoneNumberSelector);
      }
    }

    function isBrowserSupported() {
      if (isTargetDevice()) {
        return isTargetBrowser();
      }
      return false;
    }

    function isTargetDevice() {
      return (/iPhone|Android/gi).test(navigator.userAgent);
    }

    function isTargetBrowser() {
      var ua = navigator.userAgent.toLowerCase();
      var isAndroid = ((ua.indexOf('mozilla/5.0') > -1 && ua.indexOf('android') > -1 &&
        ua.indexOf('applewebkit') > -1) && (ua.indexOf('chrome') == -1) && (ua.indexOf('firefox') == -1));
      return isAndroid || (ua.indexOf('chrome') > -1 || ua.indexOf('safari') > -1);
    }

    function linkPhoneNumber(container, mpPhoneNumberSelector) {
      var span = $(container).find(mpPhoneNumberSelector);
      var number = span.text().trim();
      var telNumber = normaliseForTel(number).trim();
      $(span).html('<a href="tel:' + telNumber + '">' + number + '</a>');
      return container.html();
    }

    function normaliseForTel(number) {
      var digits = number.replace(/\D/g, '');
      if (digits.length == 10) {
        return addDashes(digits);
      }
      else {
        return number;
      }
    }

    function addDashes(number) {
      if (!number.match('^04')) {
        number = insertDash(number, 2);
        number = insertDash(number, 7);
      }
      else {
        number = insertDash(number, 4);
        number = insertDash(number, 8);
      }
      return number;
    }

    function insertDash(str, index) {
      return str.substring(0, index) + '-' + str.substring(index, str.length);
    }

    return {
      linkPhoneNumberIfTelSupported: linkPhoneNumberIfTelSupported
    };
  })();
}