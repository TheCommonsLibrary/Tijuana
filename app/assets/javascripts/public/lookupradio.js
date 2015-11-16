function lookupRadio(lookupUrl, moduleId, timeout) {
    timeout = timeout || 750;
    var postcodeField = $('#radio_postcode');
    var mpsContainer = $('#radio-lookup');
    var timeoutId;
    var lastText;

    function lookupRadios(data, status, xhr) {
        mpsContainer.html(data);
        mpsContainer.slideDown();
    }

    function getRadio() {
        var currentText = postcodeField.val();

        if (currentText != lastText) {
            mpsContainer.slideUp(40).empty();
            $.ajax({
                type:'GET',
                url:lookupUrl,
                data:{postcode:postcodeField.val(), module_id:moduleId},
                success:lookupRadios,
                dataType:'html'
            });
            lastText = postcodeField.val();
        }
    }

    function politelyLookupRadios() {
        if (timeoutId !== undefined) {
            clearTimeout(timeoutId);
        }
        timeoutId = setTimeout(getRadio, timeout);
    }

    postcodeField.bind('keyup change', politelyLookupRadios);
}

function workWithLessAndMore() {
    $("#other-shows").hide();
    $("#more-anchor").show();
    $("#less-anchor").hide();

    $("#more-anchor").bind('click', function () {
        $("#other-shows").slideDown(1000);
        $("#more-anchor").hide();
        $("#less-anchor").show();
    });
    $("#less-anchor").bind('click', function () {
        $("#other-shows").slideUp(1000);
        $("#less-anchor").hide();
        $("#more-anchor").show();
    });
}

function initialiseRadioList(currentRadioShowsPresent, otherRadioShowsPresent) {

    $(".radio_details_item").hide();
    if (currentRadioShowsPresent === true && otherRadioShowsPresent === true) {
        workWithLessAndMore();
    } else {
        $("#more-anchor").hide();
        $("#less-anchor").hide();
    }

    $(".radio_show").bind('click', function () {
        var id = $('input[name=radio_show]:checked', '#action-form').val();
        var radioDetailsSelector = "#radio_details" + id;
        $(".radio_details_item").hide();
        $(radioDetailsSelector).slideDown(1000);
    });
}

