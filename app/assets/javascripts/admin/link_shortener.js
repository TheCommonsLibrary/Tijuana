var linkShortener = function($parentDiv, userId, emailId) {
  var $pageIdField = $parentDiv.find('#page-id-field');
  var $redirectIdField = $parentDiv.find('#redirect-id-field');
  var $button = $parentDiv.find('#url-shortened-link');
  var $placeholder = $parentDiv.find('#shortened-url-placeholder');

  var validateInputFieldsAreNumericOrEmpty = function() {
    return ($pageIdField.val().match(/^[0-9]+$/) && $redirectIdField.val().match(/^[0-9]+$/)) || ($pageIdField.val() === '' && $redirectIdField.val().match(/^[0-9]+$/)) || ($pageIdField.val().match(/^[0-9]+$/) && $redirectIdField.val() === '');
  };

  $pageIdField.change(function(){
    if(validateInputFieldsAreNumericOrEmpty()) {
      $button.removeAttr('disabled');
    } else {
      $button.attr('disabled','disabled');
    }
  });

  $redirectIdField.change(function(){
    if(validateInputFieldsAreNumericOrEmpty()) {
      $button.removeAttr('disabled');
    } else {
      $button.attr('disabled','disabled');
    }
  });

  $button.click(function(){
    var pageId = $pageIdField.val() || 0;
    var redirectId = $redirectIdField.val() || 0;
    $.get("/admin/link_shortener/generate_shortened_url?user_id=" + userId + "&email_id=" + emailId + "&page_id=" + pageId + "&redirect_id=" + redirectId, function(data){
      $placeholder.html('<span>Shortened URL:</span> ' + data);
    });
  });
};