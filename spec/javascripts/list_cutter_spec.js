
describe("list cutter", function() {

  describe("list cutter maybe definition list", function () {

    beforeEach(function() {
      jasmine.getFixtures().load("list_cutter.html");
      scope = $("fieldset.list-cutter");
      list_cutter(scope);
    });	 

    describe("adding filters", function () {
      beforeEach(function() {
        add_filter_button = $(".filter-actions .add-filter");
      });

      it("should add a new empty filter when new is clicked", function () {
      	expect(scope.find("ul.list-cutter-filters>li").size()).toBe(1);
      	add_filter_button.click();
      	add_filter_button.click();
        add_filter_button.click();
        expect(scope.find("ul.list-cutter-filters>li").size()).toBe(4);
      });

      it("should append the correct fieldset based on the selected filter type", function () {
      	var filter_elem = $("ul.list-cutter-filters>li:first");
      	filter_elem.find("option[value=filter-postcode_within_rule]").prop("selected", true);
      	filter_elem.find("select").change();
      	var filter_elem_choice = filter_elem.find("ul.list-cutter-filter-value li");
        expect($(".choose-postcode_within_rule").size()).toBe(1);
      	expect(filter_elem_choice.attr("class")).toBe("choose-postcode_within_rule");
      	expect(filter_elem_choice.find(".required-if-present").hasClass("required")).toBeTruthy();
      });

      it("should update filter form when filter type changes", function () {
        add_filter_button.click();
        add_filter_button.click();
        first_li = scope.find("ul.list-cutter-filters>li:first");
        first_li.find("option[value=filter-email_domain_rule]").prop("selected", true);
        first_li.find("select").change();
        $("input#rules_email_domain_rule_domain").val("test value");
        first_li.find("option[value=filter-postcode_within_rule]").prop("selected", true);
        first_li.find("select").change();
        expect($(".choose-email_domain_rule .required-if-present").hasClass("required")).toBeFalsy();
        expect($(".choose-postcode_within_rule .required-if-present").hasClass("required")).toBeTruthy();
        expect($("input#rules_email_domain_rule_domain").val()).toBe("");
      });

      it("should delete a filter when delete button clicked", function () {
          add_filter_button.click();
          add_filter_button.click();
          first_li = scope.find("ul.list-cutter-filters>li:first");
          first_li.find("option[value=filter-email_domain_rule]").prop("selected", true);
          first_li.find("select").change();
          $("input#rules_email_domain_rule_domain").val("this is a test");
          first_li.find("span.remove-filter").click();
          expect(scope.find("ul.list-cutter-filters>li").size()).toBe(2);
      });

      it("should disable the select option for any filter that has already been used", function () {
        add_filter_button.click();
        var filter_elem_email = $($("ul.list-cutter-filters>li").get(0));
        var filter_elem_postcode = $($("ul.list-cutter-filters>li").get(1));
        filter_elem_postcode.find("option[value=filter-postcode_within_rule]").prop("selected", true);
        filter_elem_postcode.find("select").change();
        filter_elem_email.find("option[value=filter-email_domain_rule]").prop("selected", true);
        filter_elem_email.find("select").change();
        expect(filter_elem_postcode.find("option[value=filter-email_domain_rule]").prop("disabled")).toBe(true);
        expect(filter_elem_email.find("option[value=filter-postcode_within_rule]").prop("disabled")).toBe(true);
      });

      it("should re-enable the select option for a filter that has been removed", function () {
        add_filter_button.click();
        var filter_elem_email = $($("ul.list-cutter-filters>li").get(0));
        var other_filter = $($("ul.list-cutter-filters>li").get(1));
        filter_elem_email.find("option[value=filter-email_domain_rule]").prop("selected", true);
        filter_elem_email.find("select").change();
        expect(other_filter.find("option[value=filter-email_domain_rule]").prop("disabled")).toBe(true);
        first_li = scope.find("ul.list-cutter-filters>li:first");
        first_li.find("span.remove-filter").click();
        expect(other_filter.find("option[value=filter-email_domain_rule]").prop("disabled")).toBe(false);
      });

      it("should check the 'activated' checkbox for each filter added", function () { 
        var filter_elem = $($("ul.list-cutter-filters>li").get(0));
        filter_elem.find("option[value=filter-postcode_within_rule]").prop("selected", true);
        filter_elem.find("select").change();
        expect($("#rules_postcode_within_rule_activate").prop("checked")).toBe(true);
      });

      it("should initialise new filter select option to default", function() {
        var filter_elem_email = $($("ul.list-cutter-filters>li").get(0));
        filter_elem_email.find("option[value=filter-email_domain_rule]").prop("selected", true);
        filter_elem_email.find("select").change();
        add_filter_button.click();
        var new_filter = $($("ul.list-cutter-filters>li").get(1));
        var selected_options = new_filter.find('option:selected');
        expect(selected_options.val()).toEqual('filter-empty');
      });
    });
  });
});
