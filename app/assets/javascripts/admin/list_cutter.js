/*global window, $, jQuery, document */

$.fn.clear_inputs = function () {
    $(this).find(':input').each(function() {
        switch(this.type) {
            case 'password':
            case 'select-multiple':
            case 'select-one':
            case 'text':
            case 'textarea':
                $(this).val('');
                break;
            case 'checkbox':
            case 'radio':
                this.checked = false;
        }
    });
};

$.fn.dynamic_filters = function () {
    var scope = $(this),
        disabled = [],
        had_at_least_one_rule_set = false,
        disable_select_options = function (select) {
            var selected_value =  $(select).find(":selected").val();
            if (selected_value != "filter-empty") {
                disabled.push(selected_value);
                scope.find("option[value=" + selected_value + "]").attr("disabled", "disabled");
            }
            $.each(disabled, function (index, disabled_value) {
                if (scope.find("option[value=" + disabled_value + "]:selected").size() === 0) {
                    scope.find("option[value=" + disabled_value + "]").removeAttr("disabled");
                    disabled = $.grep(disabled, function(value) {
                        return value !== disabled_value;
                    });
                }
                $(select).find(":selected").removeAttr("disabled");
            });
        },
        list_cutter_filter_elem = scope.find("ul.list-cutter-filters"),
        inject_choice = function (init, options) {
            var filter,
                available_filters = $("ul.choose-toggle"),
                toggle_filter_rule = function (filter_rule, state) {
                    if (state == "on") {
                        $("#rules_" + filter_rule + "_activate").attr("checked", "checked");
                    } else {
                        $("#rules_" + filter_rule + "_activate").removeAttr("checked");
                    }
                },
                shuffle_dom_in = function (element) {
                    var filter_by = $(element).val().replace(/filter\-/gi, "");
                    var filter_ul = $(element).parent().parent().find("ul.list-cutter-filter-value");
                    filter_ul.find("li").clear_inputs();
                    filter_ul.find("label.error").remove();
                    filter_ul.find(".error:input").removeClass("error");
                    filter_ul.find(".required-if-present").removeClass("required");
                    available_filters.append(filter_ul.find("li"));
                    filter_ul.append(available_filters.find("li.choose-" + filter_by));
                    $("#activate_" + filter_by + "_rule").attr("checked");
                    filter_ul.find(".required-if-present").addClass("required");
                },
                shuffle_dom_out = function (element, last) {
                    var filter_li = $(element).find("li");
                    filter_li.find(".required-if-present").removeClass("required");
                    filter_li.clear_inputs();
                    available_filters.append(filter_li);
                    if (last) {
                        $(element).find("option[value=filter-empty]").attr("selected", "selected");
                        filter_li.clear_inputs();

                    } else {
                        $(element).remove();
                    }
                };
              if (init) {
                  filter = list_cutter_filter_elem.find(">li:first");
                  filter.find("option[value=filter-empty]").attr("selected", "selected");
              } else {
                  filter = list_cutter_filter_elem.find(">li:first").clone();
                  filter.find("ul.list-cutter-filter-value").empty();
                  filter.find('option:selected').removeAttr('selected');
                  filter.find(".filter-empty").attr('selected', 'selected');
                  disable_select_options(filter.find("select.filter-by"));
                  list_cutter_filter_elem.append(filter);
                  if (options && options.auto_populate) {
                      filter.find("select.filter-by option[value=" + options.auto_populate + "]").attr("selected", "selected");
                      disable_select_options(filter.find("select.filter-by"));
                      shuffle_dom_in(filter.find("select.filter-by"));
                  }
              }
              filter.find("select.filter-by").change(function () {
                  $(this).find("option[selected=selected]").removeAttr('selected');
                  $(this).find("option:selected").attr('selected', 'selected'); // ensure shuffle_dom_in finds the selected element in FF
                  disable_select_options(this);
                  toggle_filter_rule($(this).val().replace(/filter\-/gi, ""), "on");
                  shuffle_dom_in(this);
              });
              filter.find(".remove-filter").click(function (event) {
                  var selected_option = $(event.target).siblings("select")[0].value;
                  $('option[value="'+selected_option+'"]').removeAttr("disabled");
                  disabled = $.grep(disabled, function(value) {
                      return value != selected_option;
                  });
                  toggle_filter_rule(filter.find("select.filter-by").val().replace(/filter\-/gi, ""), "off");
                  shuffle_dom_out(filter, (scope.find("ul.list-cutter-filters li.list-cutter-filter").size() == 1));
              });
              $.each(disabled, function (index, disabled_value) {
                  filter.find("option[value=" + disabled_value + "]:not(:selected)").attr("disabled", "disabled");
              });
        };
        scope.find(".filter-actions .add-filter").click(function () {
            inject_choice(false);
        });
        inject_choice(true);
        var firstSelectBox = scope.find("select.filter-by:first");
        disable_select_options(firstSelectBox);
        firstSelectBox.find("option").each( function (index, filter_type) {
            var saved_value = scope.find("#rules_" + $(filter_type).val().replace(/filter\-/gi, "") + "_activate");
            if (saved_value.attr("checked")) {
                had_at_least_one_rule_set = true;
                inject_choice(false, {auto_populate: $(filter_type).val()});
            }
        });
        if (had_at_least_one_rule_set) {
          $("li.list-cutter-filter:first").remove();
        }
        return scope;
};

var list_cutter = function(scope) {
    $(scope).dynamic_filters();
};

var humanize = function(input) {
  return input.replace(/_/g, ' ')
    .replace(/(\w+)/g, function(match) {
      return match.charAt(0).toUpperCase() + match.slice(1);
    });
};

var periodicalUpdater = function(options) {
    if (options.resultId !== null) {
        $(options.resultsContainer).initUpdater(options);
    }
};

$.fn.initUpdater = function (options) {
    var resultId = options.resultId,
      periodicUpdaterComplete = options.complete,
      showSaveButton = options.showSaveButton,
      submitButton = options.submitButton;
    var successTemplate = "<h3 class='processed'>Found {{size}} members in {{total_time}} seconds</h3><br><br>" +
               "<strong>SQL Generated:<br></strong><div id='sql-wrapper'><pre><code class='language-sql'>{{sql}}</code></pre></div>";
    var errorTemplate = "<h3 class='error'>An error occurred: {{error}}</h3><br><br>";
    if(showSaveButton) {
        successTemplate = successTemplate + "<input type='button' id='save-list' value='Save'>";
    }
    var that = this;

    function renderedResult(result) {
        if (result.error) {
            return Mustache.to_html(errorTemplate, result);
        } else {
            return Mustache.to_html(successTemplate, result);
        }
    }

    var updater = $.PeriodicalUpdater('/admin/list_cutter/poll?result_id=' + resultId, {
        method: 'get',          // method; get or post
        data: '',               // array of values to be passed to the page - e.g. {name: "John", greeting: "hello"}
        minTimeout: 2000,       // starting value for the timeout in milliseconds
        maxTimeout: 10000,       // maximum length of time between requests
        multiplier: 2,          // if set to 2, timerInterval will double each time the response hasn't changed (up to maxTimeout)
        type: 'text',           // response type - text, xml, json, etc.  See $.ajax config options
        maxCalls: 0,            // maximum number of calls. 0 = no limit.
        autoStop: 0             // automatically stop requests after this many returns of the same data. 0 = disabled.
    },
    function(data) {
        var result = JSON.parse(data);
        if (result.ready) {
            $(that).html(renderedResult(result));
            $(that).show();
            Prism.highlightAll();
            updater.stop();
            periodicUpdaterComplete();
            $(submitButton).removeAttr('disabled');
        }
    });
};
