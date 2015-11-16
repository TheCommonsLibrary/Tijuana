
/*
 * [{
 *   displays: ["opens", "clicks", "actions-taken", "new-members", "unsubscribed"]
 *   as_percentage_of: "sent-to"
 * }]
 *
 */

$.fn.show_percentages = function (options) {
  var table = this;
  $.each(options, function(_, set) {
    $.each(set.displays, function (_, value_box_class) {
      $(table).find("." + value_box_class).each(function (_, value_box) {
        var total = parseInt($(value_box).parent().find("." + set.as_percentage_of).text(), 10),
            current = parseInt($(value_box).text(), 10);

        if (!isNaN(total*current) && total*current > 0) {
          $(value_box).append("<span class=\"percentage\"> (" + Math.round((current/total)*100) + "%) </span>");
        }
      });
    });
  });
  return $(this);
};
