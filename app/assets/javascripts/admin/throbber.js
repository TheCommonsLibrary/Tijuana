function displayThrobber(actionTarget) {
  function ajaxComplete(e, data, status, xhr) {
    $.throbberHide();
  }

  $(actionTarget).bind("ajax:success", ajaxComplete);
  
  $(actionTarget).throbber("ajax:loading", {image: ajaxWaitImagePath});
}