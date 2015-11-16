describe("configuration of the email MP module", function () {
    beforeEach(function () {
        jasmine.getFixtures().load("mp_module_jurisdiction_and_party_select.html");
    });

    describe("toggle jurisdiction", function () {
        it("should show the right parties for jurisdiction New South Wales", function () {
            var ajaxStub = sinon.stub($, 'ajax', function (options) {
                options.success("OK");
            });
            initEmailMpModule({url:"/someurl", data:"module_id=15", resultsContainer:"#parties", upperHousePresent:true });
            $("#jurisdiction-select").val("Queensland").change();
            $.ajax.restore();
            expect($('#target-selection').attr("style").trim()).toBe("display: none;");
            expect(ajaxStub.calledOnce).toBe(true);
        });

        it("should not display target senate on page reload when there is no upper house for the jurisdiction", function () {
            var ajaxStub = sinon.stub($, 'ajax', function (options) {
                options.success("OK");
            });
            initEmailMpModule({url:"/someurl", data:"module_id=15", resultsContainer:"#parties", upperHousePresent:false });
            $.ajax.restore();
            expect($('#target-selection').attr("style").trim()).toBe("display: none;");
        });

        it("should display target senate on page reload when there is a upper house for the jurisdiction", function () {
            var ajaxStub = sinon.stub($, 'ajax', function (options) {
                options.success("OK");
            });
            initEmailMpModule({url:"/someurl", data:"module_id=15", resultsContainer:"#parties", upperHousePresent:true });
            $.ajax.restore();
            expect($('#target-selection').attr("style")).toBe('display: block;');
        });

        it("should set target to 'MPs' when upper house not present for queensland", function () {
            var ajaxStub = sinon.stub($, 'ajax', function (options) {
                options.success("OK");
            });
            $("#target-selection select").val('Senator');
            initEmailMpModule({url:"/someurl", data:"module_id=15", resultsContainer:"#parties", upperHousePresent:true });
            expect($("#target-selection select").val()).toBe("Senator");
            $("#jurisdiction-select").val("Queensland").change();
            $.ajax.restore();
            expect($("#target-selection select").val()).toBe('MP');
        });
    });
});
