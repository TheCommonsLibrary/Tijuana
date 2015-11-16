function initBlastCountdown(container, until) {
  if (until <= 0) {
    container.html("Delivery in progress...");
    return;
  }
  $(container).countdown({
      until: until,
      format: "MS",
      layout: "Delivery in {mn}:{snn} ",
      onExpiry: function() {
        container.html("Delivery in progress... ");
      }
    });
}

$.fn.blasts = function () {
  var scope = $(this);

  scope.find(".all-members input[type=checkbox]").removeAttr("checked");
  scope.find(".all-members input[type=checkbox]").change(function () {
    if ($(this).attr("checked")) {
      $(this).parent().parent().find(".send-number").attr("disabled", "disabled");
    } else {
      $(this).parent().parent().find(".send-number").removeAttr("disabled");
    }
  });

  scope.find(".reload-page").click(function () {
    window.location.reload();
  });

  $.each(scope.find("li.blast .in-progress"), function(index, elem) {
    var countdownElem = $(elem).find(".countdown");
    var until = parseFloat(countdownElem.html());
    initBlastCountdown(countdownElem, until);
  });

};
