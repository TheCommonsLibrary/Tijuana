function updateCard(donation_id, recurring_donation_path, error_image_path, success_image_path) {
  var formSelector = $('#update-donation-form-' + donation_id);
  var submitBtnSelector = $('button', formSelector);
  
  function saveAndValidate() {
    formSelector.validate();
    submitBtnSelector.click(function (e) {
      if (formSelector.valid()) {
        submitBtnSelector.prop('disabled', true);
        submitBtnSelector.html('Saving...');
        $.ajax({
          type:'PUT',
          url: recurring_donation_path,
          data: formSelector.serialize(),
          success: updateSuccessful(),
          error: errorHandler(),
          dataType:'json'
        });
        
      } else {
        //show errors on the page
        formSelector.validate().form();
      }
      return false;
    });
  }

  function errorHandler() {
    var self = this;
    return function (request, error) {
      submitBtnSelector.val(self.submitText);
      try{
        var errors = formatErrors($.parseJSON(request.responseText));
        $.gritter.add({image:error_image_path, sticky:true, title:'Error', text:errors});
      } catch(e){
        console.log("Error accessing server");
        $.gritter.add({image:error_image_path, sticky:true, title:'Error', text:"Oops!! Something went wrong while trying to make a request. Request aborted!"});
      }
      submitBtnSelector.prop('disabled', false);
      submitBtnSelector.html('Save');
      
    };
  }

  formatErrors = function(thisError) {
    var errorString = '';
    $.each(thisError, function (key, value) {
      errorString += key + " " + value + ". ";
    });
    return errorString;
  };


  function updateSuccessful() {
    return function (data) {
       $(submitBtnSelector).val('Save').removeProp('disabled');
      if (data !== undefined && data.status == "Error") {
        $.gritter.add({image: error_image_path, sticky:true, title:'Error', text:'There was a problem!<br>' + data.errors});
      } else {
         $('#masked-card-number').html(data.masked_card_number).after('<br />Your card has been updated.');
         $(submitBtnSelector).val("");
         $('.hide-when-done').hide('slow');
         $.gritter.add({image: success_image_path, sticky:true, title:'Success', text:'Your payment information has been updated!'});
      }
    };
  }
  saveAndValidate();
}
