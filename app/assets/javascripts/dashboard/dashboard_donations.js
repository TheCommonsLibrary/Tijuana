var GetUp = GetUp || {};
GetUp.Dashboard = GetUp.Dashboard || {};

GetUp.Dashboard.DonationsForm = (function ($) {
    function DonationsForm(options) {
        this.validate = options.validate;
        this.donationId = options.donationId;
        if (this.validate) {
            $(options.formSelector).validate();
        }
        GetUp.Dashboard.UserForm.call(this, options);
    }

    DonationsForm.prototype = new GetUp.Dashboard.UserForm({});
    DonationsForm.prototype.constructor = DonationsForm;
    DonationsForm.prototype._setupSubmitHandler = function () {
        var self = this;
        $(this.formSelector + ' input[type=submit]').click(function (e) {
            self.submitHandler();
        });
    };

    DonationsForm.prototype.submitHandler = function () {
        var self = this;
        if (self.validate && !$(self.formSelector).valid()) {
            return false;
        }
        var form = $(self.formSelector);
        $(self.formSelector + ' input[type=submit]').val(self.processingText);
        $.ajax({
            type:'PUT',
            url:self.url,
            data:form.serialize(),
            success:self._successHandler(),
            error:self._errorHandler(),
            dataType:self.ajaxDataType
        });
    };

    DonationsForm.prototype._successHandler = function () {
        var self = this;
        return function (data) {
            $(self.formSelector + ' input[type=submit]').val(self.submitText);
            if (data !== undefined && data.status == "Error") {
                self._gritter_error(data.errors);
            } else {
                $('#donation-' + self.donationId + '-card-number-helper ~ div:first').html(data.masked_card_number);
                self._gritter_success('Your payment information has been updated!');
            }
        };
    };

    return DonationsForm;
})($);


GetUp.Dashboard.CancelRecurringDonationsForm = (function ($) {
    function CancelRecurringDonationsForm(options) {
        this.donationsContainer = options.donationsContainer;
        GetUp.Dashboard.DonationsForm.call(this, options);

    }

    CancelRecurringDonationsForm.prototype = new GetUp.Dashboard.DonationsForm({});
    CancelRecurringDonationsForm.prototype.constructor = CancelRecurringDonationsForm;

    CancelRecurringDonationsForm.prototype._successHandler = function () {
        var self = this;
        return function (data) {
            if (data !== undefined && data.status == "Error") {
                self._gritter_error(data.errors);
            } else {
                $(self.formSelector).parent('div').parent('div').hide();
                if ($(self.donationsContainer + ' > div:visible').length === 0) {
                    $(self.donationsContainer).append("<div class='content-box'><p>You don't have any recurring donations. Would you like to <a class='anchor' href='/donate' title='Donate Now'>start donating now</a>?</p></div>");
                }
                self._gritter_success('Your donation has been cancelled!');
            }
        };
    };

    CancelRecurringDonationsForm.prototype._setupSubmitHandler = function () {
        var self = this;
        $(this.formSelector + ' input[type=submit]').click(function (e) {
            if (confirm("Are you sure?")) {
                self.submitHandler();
            } else {
                return false;
            }

        });
    };

    CancelRecurringDonationsForm.prototype._disableFormButtons = function () {
    };


    return CancelRecurringDonationsForm;

})($);


GetUp.Dashboard.UpdateReceiptFrequencyForm = (function ($) {
    function UpdateReceiptFrequencyForm(options) {
        this.donationsContainer = options.donationsContainer;
        GetUp.Dashboard.DonationsForm.call(this, options);

    }

    UpdateReceiptFrequencyForm.prototype = new GetUp.Dashboard.DonationsForm({});
    UpdateReceiptFrequencyForm.prototype.constructor = UpdateReceiptFrequencyForm;

    return UpdateReceiptFrequencyForm;

})($);
