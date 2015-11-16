function hostEmail() {
  if($("#host_email").val().length === 0) {
    return $("#host_email").html();
  } else {
    return $("#host_email").val();
  }
}

function extractFormValuesInto(eventSummaryContainer) {
  var container = $(eventSummaryContainer);
  container.find('#confirm-address').html($('#event_address').val());
  container.find('#confirm-date').html($("#event-calendar").val());
  container.find('#confirm-time').html($('#event_hour option:selected').text() + ':' + $('#event_minute option:selected').text());
  container.find('#confirm-email').html(hostEmail());
  container.find('#confirm-name').html($("#event_name").val());
  container.find('#confirm-phone').html($("#event_phone").val());
  container.find('#confirm-capacity').html($("#event_capacity").val());
  container.find('#confirm-notes').html(escape_html($("#event_host_notes").val()));
}

function setupTabs(tabsSelector) {
  $(tabsSelector).tabs({
    select: function(event, ui) {
      switch (ui.index) {
        case 0:
          $('.step-1-tab').addClass("bg-left-unselected-step");
          $('.step-2-tab').addClass("no-bg");
          $('.step-2-tab').addClass("bg-right-unselected-step");
          break;
        case 1:
          if (!$('#event_address').valid()) {
            return false;
          }
          $('.step-1-tab').addClass("bg-left-unselected-step");
          $('.step-2-tab').addClass("no-rounded-corners");
          $('.step-2-tab').removeClass("bg-left-unselected-step");
          break;
        case 2:
          if (!$('#step-2-content input:not(.ignore)').valid()) {
            return false;
          }
          extractFormValuesInto(".event-summary");
          $('.step-1-tab').removeClass("bg-left-unselected-step");
          $('.step-2-tab').addClass("bg-left-unselected-step");
          $('.step-2-tab').removeClass("bg-right-unselected-step");
          $('.step-3-tab').addClass("no-rounded-corners");
          $('.step-3-tab').addClass("no-bg");
          break;
      }
    }
  });
}

function makeSureTocWasAccepted(formSelector) {
  $(formSelector).submit(function(e){
    if(!$('#event_terms_and_conditions').valid()) {
      e.preventDefault();
      return false;
    }
  });
}

jQuery.validator.addMethod("accepts", function(value, element) {
  return $('input[name="' + element.name + '"][type=checkbox]').attr('checked');
}, "You must accept the terms and conditions");

function setupHourOptions(options) {
  if (!options.hasTimeRestriction){return;}
  $.each($(options.inputSelector).find('option'), function(i, val) {
    var optionValue = parseInt($(val).val(), 10);
    if (optionValue < options.fromHour || optionValue > options.toHour) {
        $(val).remove();
    }
  });
}
