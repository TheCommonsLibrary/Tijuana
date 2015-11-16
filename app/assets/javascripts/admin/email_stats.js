var throbber = "<p class='loading'><img src='/assets/admin/lib/colorbox/loading.gif' />Fetching your statistics...</p>";

$(document).ready(function() {
  $('#email-stats button').on('click', function() {
    $.ajax({
      url: $(location).attr('href') + '/stats',
      dataType: 'html',
      beforeSend: function() {
        $('#email-stats button').attr('disabled', true);
        $('.js-stats-table').empty().html(throbber);
      },
      success: function(data) {
        $('.js-stats-message').empty();
        $('.js-stats-table').html(data);
      },
      error: function() {
        $('.js-stats-message').html('<p>There was a problem fetch your statistics, please try again in a few moments.</p>');
      },
      complete: function() {
        $('#email-stats button').removeAttr('disabled');
      }
    });
  });
});
