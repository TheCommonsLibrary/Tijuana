function emailFormValidation(opts) {
  if (tijuana.isTestEnvironment()) {
    if ( (opts.subjectHidden !== true) && $('#user_email_subject').length === 0) { throw 'Expected to have a field with id #user_email_subject'; }
    if ($('#user_email_body').length === 0) { throw 'Expected to have a field with id #user_email_body'; }
  }
  
  return function() {
    function subjectRequiredButEmpty(opts, obj) {
      return ( ($(obj).find("#user_email_subject").val() === "")) ;
    }

    if (opts.placeholders) {
      if ( subjectRequiredButEmpty(opts, this) ) {
        $(this).data("error", "A subject is required");
      } else if ($(this).find("#user_email_body").val() === "") {
        $(this).data("error", "A message is required");
      }
    } else {
      if ( subjectRequiredButEmpty(opts, this) || $(this).find("#user_email_body").val() === "") {
        $(this).data("warning", "You have entered a blank subject or message, would you like to send the defaults?");
      }
    }
  };
}
