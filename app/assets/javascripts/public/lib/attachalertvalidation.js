$.fn.attachAlertValidation = function(validation) {
  $(this).bind('runValidation', validation);
  
  $(this).submit(function() {
    $(this).data("error", null);
    $(this).data("warning", null);
    $(this).trigger("runValidation");
    
    if ($(this).data("error")) {
      alert($(this).data("error"));
      return false;
    }
    
    if ($(this).data("warning")) {
      return confirm($(this).data("warning"));
    }
    
    return true;
  });
};