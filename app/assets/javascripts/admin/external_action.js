function handleExternalActions(externalActionForm, tabsContainer, submittedActionsBtnBar, successMessageDiv, gritterSuccessImagePath, gritterErrorImagePath) {

  function clearErrors() {
    $('p.error').remove();
    $('div.field_with_errors').children().each(function () {
      $(this).unwrap();
    });
  }

  function addErrors(data, form) {
    var errorMessage = $('<p></p>');
    errorMessage.attr('class', 'error');

    for (var key in data.error) {
      if (data.error.hasOwnProperty(key)) {
        $('[for=' + key + ']').wrap("<div class='field_with_errors'></div>");
        $('[name=' + key + ']').wrap("<div class='field_with_errors'></div>");
        errorMessage.append(data.error[key] + '<br>');
      }
    }
    form.before(errorMessage);
  }

  externalActionForm.on('ajax:success',
    function (e, data, status, xhr) {
      clearErrors();

      if (data.error) {
        addErrors(data, $(this));
      } else if (data.page_path) {
        $.gritter.add({image: gritterSuccessImagePath, sticky: true, title: 'Success', text: 'Actions are being added. It may take a few minutes.'});

        tabsContainer.slideUp();
        successMessageDiv.html("The external actions have been added to the following page: <a href='" + data.page_path + "'>" + data.page_path + "</a>");
        successMessageDiv.show();
        submittedActionsBtnBar.show();
      }
    }
  );

  externalActionForm.on('ajax:error',
    function (e, xhr, status, error) {
      $.gritter.add({image: gritterErrorImagePath, sticky: true, title: 'Error', text: 'Ajax error occurred. Please try again.'});
    }
  );
}