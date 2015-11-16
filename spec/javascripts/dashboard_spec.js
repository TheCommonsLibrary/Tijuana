describe("Dashboard", function () {
    beforeEach(function () {
        jasmine.getFixtures().load("dashboard.html");
        $("#edit-user-form").validate();
    });

    describe("inline editing", function () {

        it("should update the given attribute on the server", function () {
            var ajaxStub = sinon.stub($, 'ajax', function (options) {
                options.success();
            });
            var gritterStub = sinon.stub($.gritter, 'add');

            new GetUp.Dashboard.UserForm({
                formSelector:'#edit-user-form',
                inlineEditingSelector:'#user-details input:not(input[type=reset]), #user-details select',
                inlineEditingDefaultText:'Click Here to Edit',
                url:'/users'
            }).init();

            expect($("#personal-details-submit-button").is(':enabled')).toBe(true);

            var element, previewElement;
            element = $("#user_first_name");
            previewElement = element.next();
            previewElement.click();
            element.val("leo");
            triggerKeyEventWithKey('keyup', element, 10);

            expect($("#personal-details-submit-button").is(':enabled')).toBe(true);

            $("#personal-details-submit-button").click();

            $.ajax.restore();
            $.gritter.add.restore();
            expect(ajaxStub.calledOnce).toBe(true);
            expect(ajaxStub.args[0][0].type).toBe('PUT');
            expect(ajaxStub.args[0][0].url).toBe('/users');
            expect(ajaxStub.args[0][0].dataType).toBe('text');
            expect(ajaxStub.args[0][0].data.match(/first_name.+leo/)).not.toBe(null);

            expect(gritterStub.calledOnce).toBe(true);
        });

    });

    describe("validation", function () {
        it("should not prevent empty values from being submitted", function () {
            var ajaxStub = sinon.stub($, 'ajax');

            new GetUp.Dashboard.UserForm({
                formSelector:'#edit-user-form',
                inlineEditingSelector:'#user-details input:not(input[type=reset]), #user-details select',
                inlineEditingDefaultText:'Click Here to Edit',
                url:'/users'
            }).init();

            var element;
            element = $("#user_first_name");
            element.val('');
            triggerKeyEventWithKey('keyup', element, 10);
            expect($("#personal-details-submit-button").is(':enabled')).toBe(true);

            element.val('This is ok');
            triggerKeyEventWithKey('keyup', element, 10);
            expect($("#personal-details-submit-button").is(':enabled')).toBe(true);

            $.ajax.restore();
            expect(ajaxStub.called).toBe(false);
        });
    });

    describe("Submit Fail", function () {
        it("should mention something fail when response text is empty", function () {
            var ajaxStub = sinon.stub($, 'ajax', function (options) {
                options.error();
            });
            spyOn($.gritter, 'add');

            new GetUp.Dashboard.UserForm({
                formSelector:'#edit-user-form',
                inlineEditingSelector:'#user-details input:not(input[type=reset]), #user-details select',
                inlineEditingDefaultText:'Click Here to Edit',
                url:'/users'
            }).init();

            var element;
            element = $("#user_first_name");
            element.val('Joe');
            $("#personal-details-submit-button").click();
            $.ajax.restore();
            expect(ajaxStub.calledOnce).toBe(true);
            expect($.gritter.add.calls.mostRecent().args[0]['title']).toEqual('Error');
        });
    });
});
