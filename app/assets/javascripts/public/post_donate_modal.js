function postDonateModal(popup, actionButton, closeButton, ajaxSubmitUrl, gritterSuccessImagePath, gritterErrorImagePath, successMessage, errorMessage) {
  popup.modal('show');

  closeButton.click(function() {
    popup.modal('hide');
  });

  actionButton.click(function() {
    $.ajax({
      data: {},
      type: 'POST',
      url: ajaxSubmitUrl,
      success: function(data) {
        $.gritter.add({
          image: gritterSuccessImagePath,
          title: 'Success',
          text: successMessage
        });
        popup.modal('hide');
      },
      error: function(data) {
        $.gritter.add({
          image: gritterErrorImagePath,
          sticky: true,
          title: 'Error',
          text: errorMessage
        });
      }
    });
  });

}
