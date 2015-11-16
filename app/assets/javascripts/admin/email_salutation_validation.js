function validateEmailSalutation(emailSalutationStatusId) {
  var REGEX = /\{NAME\|.*\}/g;
  var editor = $("textArea[name='email[body]']").data('codeMirror');

  var showHideWarning = function() {
    var emailHeader = '';

    // Get the first 3 lines of the email
    for(var i = 0; i < 3; i++) {
      emailHeader += editor.getLine(i);
    }

    if (emailHeader.match(REGEX) !== null) {
      $(emailSalutationStatusId).hide();
    } else {
      $(emailSalutationStatusId).show();
    }
  };

  editor.on('change', function(cm, change) {
    showHideWarning();
  });
  showHideWarning();
}
