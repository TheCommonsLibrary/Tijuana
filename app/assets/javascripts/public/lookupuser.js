function lookupUser(lookupUrl, paramName, paramId, emailFieldSelector, lookupResultContainerSelector, subscribeCheckboxSelector, 
    clearUserDetailsForm) {
    var emailField = $(emailFieldSelector);
    var lookupResultContainer = $(lookupResultContainerSelector);
    var $subscribeCheckbox = $(subscribeCheckboxSelector);
    var parentForm = emailField.parents('form');
    var userLookupLabel = parentForm.find('label[for="' + emailField.attr('id') + '"]');
    var lastXhr;
    var textToLookUp;
    var timeoutId;
    var validEmailRegex = /^([^@\s]+)@((?:[\-a-z0-9]+\.)+[a-z]{2,})$/i;
    var autoSubmitAfterLoadingUserDetails = false;
    var autoSubmitActionOverride;

    function emailFieldVal() {
        return $.trim(emailField.val());
    }

    var lastEmailLookedUp = emailFieldVal();

    function isValidEmailAddress(arg) {
        return validEmailRegex.test(arg);
    }

    function showUserDetails(user) {
        lookupResultContainer.find('.alert-error').hide();
        lookupResultContainer.find('.user-field').each(function () {
            var user_field = $(this).data('user-field');
            $(this).prop('disabled', !user[user_field]);
            $(this).parents('.user-field-container').toggle(user[user_field]);
        });
    }

    function hideUserDetails() {
        lookupResultContainer.find('.user-field-container').hide();
        lookupResultContainer.find('.user-field').prop('disabled', true);
    }

    function hasUser() {
        return lookupResultContainer.hasClass('user-found');
    }

    function setHasUser(arg) {
        if (arg) {
            lookupResultContainer.addClass('user-found');
        } else {
            lookupResultContainer.removeClass('user-found');
        }
    }

    function handleAutoSubmit(isUserDataComplete) {
        if (isUserDataComplete && autoSubmitAfterLoadingUserDetails) {
            if (autoSubmitActionOverride) {
                autoSubmitActionOverride();
            } else {
                parentForm.submit();
            }
        }
        autoSubmitAfterLoadingUserDetails = false;
    }

    function lookedUpUser(data, status, xhr) {
        setUserDetailsLoading(false);
        if (xhr !== lastXhr || emailFieldVal() !== textToLookUp) {
            return;
        }

        $subscribeCheckbox.toggle(data.show_subscribe);
        showLookupMessage(data.message);
        if (data.user) {
            window.LookupUserEvent.publish(data);
            showUserDetails(data.user);
            setHasUser(true);
            handleAutoSubmit(!data.user.needs_more_details);
            lookupResultContainer.slideDown();
        } else {
            hideUserDetails();
            setHasUser(false);
            lookupResultContainer.slideDown();
        }
    }

    function checkEmailAddress() {
        if (!isValidEmailAddress(textToLookUp)) {
            showHmmMessageAndPane('Hmm... Your email looks incomplete?');
            window.LookupUserEvent.publish();
        } else {
            setUserDetailsLoading(true);
            var data = { email: textToLookUp };
            if (tijuana.donationFormController){
              data.donation_amount = tijuana.donationFormController.amount();
            }
            data[paramName] = paramId;
            lastXhr = $.get(lookupUrl, data, lookedUpUser);
        }
    }

    function getUser() {
        textToLookUp = emailFieldVal();
        if (areUserDetailsLoading() || !hasTextChangedSinceLastTime()) { return; }
        lastEmailLookedUp = textToLookUp;
        lookupResultContainer.slideUp(40, checkEmailAddress);
    }

    function friendlyEagerLookupUser(e) {
        if (e.which === 9) {
          return;
        }
        if (timeoutId !== undefined) {
            clearTimeout(timeoutId);
        }
        timeoutId = setTimeout(getUser, 1400);
    }

    function showLookupMessage(message) {
        lookupResultContainer.find('.user-lookup-message').html(message).show();
    }

    function showHmmMessageAndPane(message, submittingForm) {
        setHasUser(false);
        showLookupMessage(message);
        $(subscribeCheckboxSelector).hide();
        hideUserDetails();
        lookupResultContainer.slideDown();
        if (submittingForm) { scrollIntoView(userLookupLabel); }
    }

    function scrollIntoView(selector) {
        var topOffset = $(selector).offset().top;
        if(topOffset < $(window).scrollTop()) {
            $('html, body').animate({ scrollTop: topOffset }, focusEmailField);
        }
    }

    function focusEmailField() {
        emailField.focus();
    }

    function isParentFormAutoSubmittable() {
        return parentForm.hasClass('auto-submittable');
    }

    // Hooks on to form submitted or next step event
    // Returns true if submit/continue to next step, false if more data required
    function formCompleted(e) {
        if (parentForm.data('disable-user-lookup')){
            return true;
        }
        if (areUserDetailsLoaded()) {
            return true;
        }
        if (isValidEmailAddress(emailFieldVal())) {
            if (isParentFormAutoSubmittable()) { autoSubmitAfterLoadingUserDetails = true; }
            getUser();
        } else {
            showHmmMessageAndPane('<div class="alert-block alert-error">Please enter a valid email address</div>', true);
        }
        return false;
    }

    function areUserDetailsLoaded() {
        // check if using one-click sign based off secure cookie
        if ($('#use_cookie').length){
            return true;
        }
        return hasUser() && !hasTextChangedSinceLastTime();
    }

    function areUserDetailsLoading() {
        return emailField.hasClass('loading');
    }

    function setUserDetailsLoading(arg) {
        if (arg) {
            emailField.addClass('loading');
            $('.email-wrap').addClass('loading');
        } else {
            emailField.removeClass('loading');
            $('.email-wrap').removeClass('loading');
        }
    }

    function hasTextChangedSinceLastTime() {
        return lastEmailLookedUp !== emailFieldVal();
    }

    if (clearUserDetailsForm) {
        lookupResultContainer.hide();
    }

    emailField.attr('autocomplete', 'off');
    emailField.keydown(friendlyEagerLookupUser);
    emailField.blur(getUser);

    parentForm.submit(formCompleted);

    return ({
        forceLookup: function(autoSubmitAction) {
            autoSubmitActionOverride = autoSubmitAction;
            if (formCompleted()) { autoSubmitActionOverride(); }
        },
        isCompleted: areUserDetailsLoaded
    });
}
