describe("Managing donations on the User Dashboard", function() {
    beforeEach(function() {
      jasmine.getFixtures().load("dashboard_donations.html");
    });

    describe("inline editing", function () {
        xit("should enable the toggleEdit plugin with the given options", function () {
            var options;
            var toggleEditStub = sinon.stub($.fn, "toggleEdit", function(op) { options = op; });

            new GetUp.Dashboard.DonationsForm({
                formSelector: '#update-donation-form-1',
                inlineEditingSelector: '#update-donation-form-1 input, #update-donation-form-1 select',
                url: '/donations',
                donationId: 1
            }).init();

            $.fn.toggleEdit.restore();
            expect(toggleEditStub.calledOnce).toBe(true);
            expect(options.copyCss).toBe(true);
        });

        xit("should post the entered data to the server", function() {
            var ajaxStub = sinon.stub($, 'ajax');

            new GetUp.Dashboard.DonationsForm({
                formSelector: '#update-donation-form-1',
                inlineEditingSelector: '#update-donation-form-1 input, #update-donation-form-1 select',
                url: '/donations',
                ajaxDataType:'json',
                donationId: 1
            }).init();


            $('#cc').next("div.toggleEdit").click();
            $('#cc').val('4111111111111111');

            $('#update-donation-1-submit-button').click();

            $.ajax.restore();
            expect(ajaxStub.calledOnce).toBe(true);
            expect(ajaxStub.args[0][0].type).toBe('PUT');
            expect(ajaxStub.args[0][0].url).toBe('/donations');
            expect(ajaxStub.args[0][0].dataType).toBe('json');
            expect(ajaxStub.args[0][0].data.match(/cc=4111111111111111/))
        });

        xit("should display a success message using the gritter plugin", function() {
            var ajaxStub = sinon.stub($, 'ajax', function(options) {options.success({status:"Success", masked_card_number:"XXXXXXXXXXXX1111"})}),
                gritterStub = sinon.stub($.gritter, 'add');

            new GetUp.Dashboard.DonationsForm({
                formSelector: '#update-donation-form-1',
                inlineEditingSelector: '#update-donation-form-1 input, #update-donation-form-1 select',
                url: '/donations',
                donationId: 1
            }).init();

            $('#donation-1-card-number-helper ~ div:first').click(); //click on the preview element to make the text box visible
            $('#donation-1-card-number-helper').val("4111111111111111"); //edit with something
            $('#donation-1-card-number-helper').blur();
            $('#update-donation-1-submit-button').click(); //try and submit

            $.ajax.restore();
            $.gritter.add.restore();
            expect(gritterStub.calledOnce).toBe(true);
            expect($('#donation-1-card-number-helper ~ div:first').html()).toBe("XXXXXXXXXXXX1111");
        });

        xit("should display an error message using the gritter plugin", function() {
            var ajaxStub = sinon.stub($, 'ajax', function(options) {options.success({status:"Error"})}),
                gritterStub = sinon.stub($.gritter, 'add');

            new GetUp.Dashboard.DonationsForm({
                formSelector: '#update-donation-form-1',
                inlineEditingSelector: '#update-donation-form-1 input, #update-donation-form-1 select',
                url: '/donations',
                donationId: 1
            }).init();

            $('#update-donation-1-submit-button').click();

            $.ajax.restore();
            $.gritter.add.restore();
            expect(gritterStub.calledOnce).toBe(true);
            expect(gritterStub.args[0][0].title).toBe("Error");
        });

        xit("should mirror the credit card number from the helper field", function() {
            new GetUp.Dashboard.DonationsForm({
                formSelector: '#update-donation-form-1',
                inlineEditingSelector: '#update-donation-form-1 input, #update-donation-form-1 select',
                url: '/donations',
                validate:true,
                donationId: 1
            }).init();

            $('#donation-1-card-number-helper ~ div:first').click(); //click on the preview element to make the text box visible
            $('#donation-1-card-number-helper').val("1"); //edit with something
            $('#donation-1-card-number-helper').blur();

            expect($('#donation_1_card_number').val()).toBe('1');
        });

        xit("should validate the credit card number", function() {
            var ajaxStub = sinon.stub($, 'ajax');

            new GetUp.Dashboard.DonationsForm({
                formSelector: '#update-donation-form-1',
                inlineEditingSelector: '#update-donation-form-1 input, #update-donation-form-1 select',
                url: '/donations',
                validate:true,
                donationId: 1
            }).init();

            $('#donation-1-card-number-helper ~ div:first').click(); //click on the preview element to make the text box visible
            $('#donation-1-card-number-helper').val("1"); //edit with something

             //edit with something
            $('#donation-1-card-number-helper').blur();
            $('#update-donation-1-submit-button').click(); //try and submit

            $.ajax.restore();
            expect($('#donation_1_card_number').val()).toBe("1");
            expect($('#donation-1-card-number-helper').is(":visible")).toBe(true);
            expect(ajaxStub.calledOnce).toBe(false);
        });
    });

    describe("cancel recurring donation", function(){
        it("should post data to cancel recurring donation", function (){
            confirmStub = sinon.stub(window, 'confirm')
            confirmStub.returns(true);

            var ajaxStub = sinon.stub($, 'ajax'),
                gritterStub = sinon.stub($.gritter, 'add');

            new GetUp.Dashboard.CancelRecurringDonationsForm({
                formSelector: '#cancel-donation-1-form',
                url: '/donations/disable',
                ajaxDataType: 'json',
                donationsContainer:  '#donations-details'
            }).init();


            $('#cancel-donation-1-submit-button').click();

            $.ajax.restore();
            $.gritter.add.restore();
            confirmStub.restore();

            expect(ajaxStub.calledOnce).toBe(true);
            expect(ajaxStub.args[0][0].type).toBe('PUT');
            expect(ajaxStub.args[0][0].url).toBe('/donations/disable');
            expect(ajaxStub.args[0][0].dataType).toBe('json');
        });

        it("should display generic message is there are no more donations left to cancel", function (){
            var ajaxStub = sinon.stub($, 'ajax', function(options) { options.success({status:"Success"})}),
                gritterStub = sinon.stub($.gritter, 'add');

            confirmStub = sinon.stub(window, 'confirm')
            confirmStub.returns(true);

            new GetUp.Dashboard.CancelRecurringDonationsForm({
                formSelector: '#cancel-donation-1-form',
                url: '/donations/disable',
                ajaxDataType: 'json',
                donationsContainer:  '#donations-details'
            }).init();

            new GetUp.Dashboard.CancelRecurringDonationsForm({
                formSelector: '#cancel-donation-2-form',
                url: '/donations/disable',
                ajaxDataType: 'json',
                donationsContainer:  '#donations-details'
            }).init();

            $('#cancel-donation-1-submit-button').click();
            var htmlAfterFirstClick = $('#donations-details').html();
            $('#cancel-donation-2-submit-button').click();
            var htmlAfterSecondClick = $('#donations-details').html();

            $.ajax.restore();
            $.gritter.add.restore();
            confirmStub.restore();

            expect(htmlAfterFirstClick.match(/You don't have any recurring donations/)).toBeFalsy();
            expect(htmlAfterSecondClick.match(/You don't have any recurring donations/)).toBeTruthy();
            expect(ajaxStub.calledTwice).toBe(true);
        });
    });

});
