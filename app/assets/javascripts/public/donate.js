function donationForm(
    paypalFormId,
    paypalFrequencyId,
    paypalBusiness,
    paypalItemName,
    paypalItemNumber,
    paypalCompletedUrl,
    paypalCancelUrl,
    paypalIpnUrl,
    gritterErrorImagePath) {

    var paypalFormElem = $(paypalFormId);
    var paypalFrequencyElem = $(paypalFrequencyId);

    function selectedAmount() {
        var value = $("#paypal .suggested-amount input:checked").val();
        if (value === "other") {
            var raw_value = $("#paypal input[name='donation[custom_amount_in_dollars]']").val();
            value = /\$?([0-9\.]*)/.exec(raw_value)[1];
        }
        return value;
    }

    function paypalFrequency() {
        switch (paypalFrequencyElem.val()) {
            case 'one_off':
                return 'one_off';
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
        paypalFormElem.append("<input type='hidden' name='" + name + "' value='" + value + "'>");
    }

    function replaceWithHiddenField(name, value) {
        paypalFormElem.find('input[name="' + name + '"]').replaceWith("<input type='hidden' name='" + name + "' value='" + value + "'>");
    }


    function setRecurringForm(amount) {
        $('#paypal-occult-form input[type=hidden]').remove();
        replaceWithHiddenField('cmd', '_xclick-subscriptions');
        appendHiddenField('sra', '1');
        appendHiddenField('src', '1');
        appendHiddenField('a3', amount);
        appendHiddenField('p3', '1');
        appendHiddenField('t3', paypalFrequency());
    }

    function setOneOffForm(amount) {
        $('#paypal-occult-form input[type=hidden]').remove();
        appendHiddenField('amount', amount);
    }

    function donateButtonClicked(event) {
        var paymentMethod = $(".nav-tabs .active a").text();
        paymentMethod = $.trim(paymentMethod).toLowerCase();
        if (paymentMethod === "paypal") {
            event.preventDefault();
            var amount = selectedAmount();
            if (amount > 0) {
                clearErrorMessage();
                if (paypalFrequency() !== null && paypalFrequency() !== 'one_off') {
                    setRecurringForm(amount);
                } else {
                    setOneOffForm(amount);
                }
                $('#occult-paypal-form').submit();
            } else {
                showErrorMessage('Please only enter digits, optionally with one decimal point, eg 5.50');
            }
        }
    }


    var errorMessageId;

    function clearErrorMessage() {
        if (errorMessageId) {
            $.gritter.remove(errorMessageId);
        }
    }

    function showErrorMessage(text) {
        if (!errorMessageId) {
            // If you call gritter.removeAll just before adding another message, the new message is removed as well
            errorMessageId = $.gritter.add({image: gritterErrorImagePath, sticky: true, title: 'Error', text: text});
        }
    }

    function showTab(type) {
        $('.tabbable a[data-payment-method="'+type+'"]').tab('show');
    }

    function showQuickdonateTab() {
        showTab('quick-donate');
    }

    function populateQuickdonateTab(cardInfo) {
        if (cardInfo) {
            $('#quick-donate .invitation').hide();
            $('#quick-donate .active').show();
            $('#quick-donate .card-info').html(cardInfo);
        }
    }

    function clearQuickdonateTab() {
        $('.tabbable a[data-payment-method="credit"]').tab('show');
        $('#quick-donate .invitation').show();
        $('#quick-donate .active').hide();
    }

    LookupUserEvent.subscribe(function (data) {
        if (data.quick_donate_card_info) {
            populateQuickdonateTab(data.quick_donate_card_info);
            showQuickdonateTab();
        } else {
            clearQuickdonateTab();
            $('.tabbable a[data-payment-method="credit"]').tab('show');
        }
    });

    if ($('#donation_quick_donation').val() === 'true') {
        showQuickdonateTab();
    }

    $(".js-tab").show();
    $(".no-js-tab").hide();

    $(".suggested-amount").hide();
    $('input[type=text].js-amount-other').each(function () {
        var tabId = $(this).parents('.tab-pane').attr('id');
        $(this).detach().insertAfter('#' + tabId + ' .others button');
    });
    $(".js-button-layout").show();

    $('.js-button-layout button, input[type=text].js-amount-other').each(function () {
        $(this).on('click', function (event) {
            var amount = $(this).data('amount');
            $("[class*='js-amount-']").removeClass('active');
            if ($(".js-amount-"+amount).length > 0) {
                $(".js-amount-"+amount).addClass('active');
            } else {
                $("button.js-amount-other").addClass('active');
            }
        });
    });

    // propagate "other" value to all input boxes
    $('input.js-amount-other').blur(function(e){
        var val = $(e.target).val();
        $('input.js-amount-other').val(val);
    });

    function setActiveAmountRadioButton() {
        var $activeTab = $('.tab-pane.active');
        var amount = $activeTab.find("[class*='js-amount-']").filter('.active').data('amount');
        $activeTab.find('input[type=radio][data-amount=' + amount + ']').prop('checked', true);
    }

    $('.js-donate-button').on('click', function (event) {
        setActiveAmountRadioButton();
        donateButtonClicked(event);
    });

    $(".donation .otherbtn").each(function () {
        $(this).on('click', function (event) {
            $(this).parents('.tab-pane').find('.otheramount').focus();
        });
    });

    $(".donation .otheramount").each(function () {
        $(this).on('focus', function (event) {
            var $parent = $(this).parents('.tab-pane');
            $parent.find('.donation .btn').removeClass("active");
            $parent.find('.donation .otherbtn').addClass('active');
            $parent.find('input[type=radio][data-amount=other]').prop('checked', true);
        });
    });

    $(".donation .btn").each(function () {
        $(this).on('click', function (event) {
            $('.donation .otheramount').val("");
        });
    });

    $('a[data-toggle="tab"]').on('shown', function (event) {
        paymentMethod = $(this).text();
        paymentMethod = $.trim(paymentMethod).toLowerCase();
        $('.ask-submit-button').css("display", "block");
        if (paymentMethod === "cheque") {
            $('.ask-submit-button').css("display", "none");
        }
    });

    function checkSelectedAmountInput(tabSelector) {
        var selectedAmount = $(tabSelector).find('.donation button.active').data('amount');
        $(tabSelector).find('.suggested-amount input[type=radio][data-amount=' + selectedAmount + ']').prop('checked', true);
    }

    $('.tabbable a[data-payment-method="credit"]').on('shown', function () {
        $('#donation_quick_donation').val('0');
        $('.payment-input').prop('disabled', true);
        $('#credit .payment-input').prop('disabled', false);
        checkSelectedAmountInput('#credit');
    });

    $('.tabbable a[data-payment-method="paypal"]').on('shown', function () {
        $('#donation_quick_donation').val('0');
        $('.payment-input').prop('disabled', true);
        $('#paypal .payment-input').prop('disabled', false);
        checkSelectedAmountInput('#paypal');
    });

    $('.tabbable a[data-payment-method="quick-donate"]').on('shown', function () {
        $('#donation_quick_donation').val('1');
        $('.payment-input').prop('disabled', true);
        $('#quick-donate .payment-input').prop('disabled', false);
        checkSelectedAmountInput('#quick-donate');
    });

    // Tab control links inside tab content act like tab headings
    $('.tab-pane a[data-toggle="tab"]').click(function(){
        showTab($(this).data('payment-method'));
    });


}

