describe("Dashboard's donation history", function() {
    beforeEach(function() {
        jasmine.getFixtures().load("dashboard_donation_history.html");
    });

    describe("filtering transactions", function () {
        it("should make an ajax request with the provided dates", function () {
            var ajaxStub = sinon.stub($, 'ajax', function (options) {
                options.success("OK");
            });

            initDonationHistory({
                formSelector: '#donation-history-form',
                url: '/dashboard/donation-history',
                resultsContainer: '#donation-history-results'
            });

            $('#from').val("01-01-2012");
            $('#to').val("05-02-2013");
            $('#donation-history-submit-button').click();

            $.ajax.restore();
            expect(ajaxStub.calledOnce).toBe(true);
            expect(ajaxStub.args[0][0].url).toBe('/dashboard/donation-history');
            expect(ajaxStub.args[0][0].dataType).toBe('html');
            expect(ajaxStub.args[0][0].data.match(/from=01-01-2012&to=05-02-2013/)).not.toBe(null);
            expect($("#donation-history-results").html()).toBe("OK");
        });

    });

});
