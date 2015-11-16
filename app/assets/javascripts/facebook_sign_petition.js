var signWithFacebook = function(appId, facebookDiv, url, pageId, moduleId) {
  var $button = facebookDiv.find('.fb-button');
  var $loader = facebookDiv.find('.fb-loader');
  var $error = facebookDiv.find('.fb-error');
  var isLoggedIntoFB = false;
  var retriedLogin = false;
  var errorFromServer = 'There was a problem signing with Facebook. Please try again or sign with email.';
  var noEmailDefinedInFacebook = 'Unable to sign with Facebook. Please sign with email.';

  var initialize = function() {
    FB.init({
      appId      : appId,
      version    : 'v2.7',
      status     : false, // check login status
      cookie     : true, // enable cookies to allow the server to access the session
      xfbml      : true  // parse XFBML
    });

    FB.getLoginStatus(function(response){
      if(response.status === 'connected') {
        checkGrantedPermissions();
      }
    });
  };

  var checkGrantedPermissions = function(){
    FB.api('/me/permissions', function(response){
      response.data.forEach(function(element){
        if(element.permission === 'email' && element.status === 'granted') {
          isLoggedIntoFB = true;
        }
      });
    });
  };

  var buttonClicked = function() {
    $button.button('loading');
    $loader.show();
    $error.empty();
    if(!isLoggedIntoFB){
      FB.login(function(response){
        if(response.status === 'connected'){
          signWithFacebookDetails();
        } else if (response.status === 'not_authorized' || response.status === 'unknown'){
          $loader.hide();
          $button.button('reset');
        } else {
          displayErrorMessage(errorFromServer);
          $loader.hide();
          $button.button('reset');
        }
      },{scope: 'email,user_location', auth_type: 'rerequest'});
    } else {
      signWithFacebookDetails();
    }
  };

  var signWithFacebookDetails = function() {
    FB.api('/me', 'get', {fields: 'id,first_name,last_name,email,location'}, function(response){
      if(typeof response.error !== 'undefined') {
        isLoggedIntoFB = false;
        displayErrorMessage(errorFromServer);
        $button.button('reset');
      } else if(typeof response.email === 'undefined') {
        displayErrorMessage(noEmailDefinedInFacebook);
        $button.button('reset');
      } else {
        var petitionDetails = getPetitionDetails(response);
        submitPetitionSignature(petitionDetails);
      }
    });
  };

  var getPetitionDetails = function(fbUserObject) {
    var petitionDetails = {
      t: $('form#action-form').find('input[name=t]').val(),
      page_id: pageId,
      module_id: moduleId,
      facebook_id: fbUserObject.id,
      first_name: fbUserObject.first_name,
      last_name: fbUserObject.last_name,
      email: fbUserObject.email
    };

    if(fbUserObject.location && fbUserObject.location.name){
      petitionDetails.suburb = fbUserObject.location.name.split(',')[0];
    }

    return petitionDetails;
  };

  var submitPetitionSignature = function(petitionDetails) {
    $.post( url, petitionDetails)
      .done(function(data, textStatus, response) {
        window.location = response.getResponseHeader('location');
      })
      .fail(function() {
        $loader.hide();
        displayErrorMessage(errorFromServer);
        $button.button('reset');
      }
    );
  };

  var displayErrorMessage = function(message) {
    $error.empty();
    $error.append('' +
      '<div class="alert alert-error">' +
      '<button class="close" type="button" data-dismiss="alert">×</button>' +
      message +
      '</div>'
    );
  };

  $button.click(buttonClicked);
  initialize();
};
