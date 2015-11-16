var codeMirrorPlugin = function (textAreaId, errorMessages) {
  var errors = {};
  var errorsSize;
  var $helpText;
  var $textArea = $(textAreaId);

  var createCodeMirrorEditor = function (domTextArea) {
    var cm = CodeMirror.fromTextArea(domTextArea, {
      mode: "htmlmixed",
      lineNumbers: true,
      autoCloseTags: true,
      matchTags: {bothTags: true},
      lineWrapping: true,
      theme: (domTextArea.disabled) ? "disabled" : "default",
      readOnly: domTextArea.disabled,
      gutters: ["CodeMirror-linenumbers", "errors"]
    });

    $textArea.data('codeMirror', cm);

    return cm;
  };

  var editor = createCodeMirrorEditor($textArea[0]);

  var addNewDivsToDOM = function () {
    $textArea.before("<div class='error-help-text'>Hover over <span></span> for error message</div>");
    $helpText = $textArea.parent().find(".error-help-text");
  };

  var populateErrorsFromErrorMessages = function () {
    errorsSize = 0;
    if (errorMessages) {
      var DECIMAL = 10;

      for (var i = 0; i < errorMessages.length; i++) {
        errorMessages[i] = errorMessages[i].replace(/\^/g, "");
        if (errorMessages[i].search("line") === 0) {
          var errorMessage = errorMessages[i].trim().split(":");
          var lineNumber = parseInt(errorMessage[0].substr("line ".length), DECIMAL);

          errors[lineNumber] = (errors[lineNumber]) ? errors[lineNumber] + "\n• " +errorMessage[1] : "• " + errorMessage[1];
          errorsSize++;
        }
      }
    }
  };

  var addErrorsToMargin = function () {
    for (var key in errors) {
      if(errors.hasOwnProperty(key)) {
        var $errorNode = document.createElement("div");
        $errorNode.setAttribute("class", "lint-error-icon");
        $errorNode.setAttribute("data-toggle", "tooltip");
        $errorNode.setAttribute("data-placement", "left");
        $errorNode.setAttribute("title", errors[key]);

        editor.setGutterMarker(key - 1, "errors", $errorNode);
      }
    }
  };

  var addErrorCountHeader = function () {
    if (errorsSize > 0) {
      var errorNode = document.createElement("div");
      errorNode.setAttribute("class", "lint-error");
      var pluralizedError = (errorsSize > 1) ? "There are " + errorsSize + " errors" : "There is " + errorsSize + " error";
      errorNode.innerHTML = "<span class='lint-error-icon'></span>" + pluralizedError;
      $textArea.siblings('.CodeMirror').prepend(errorNode);
    }
  };

  var displayErrorMessageHelper = function () {
    if (errorsSize > 0) {
      $helpText.show();
    }
  };

  addNewDivsToDOM();
  populateErrorsFromErrorMessages();
  addErrorsToMargin();
  addErrorCountHeader();
  displayErrorMessageHelper();

  $textArea.bind("DOMSubtreeModified", function () {
    if($textArea[0].disabled !== editor.getOption("readOnly")) {
      editor.toTextArea();
      editor = createCodeMirrorEditor($textArea[0]);
      populateErrorsFromErrorMessages();
      addErrorsToMargin();
      addErrorCountHeader();
    }
  });

  $('.CodeMirror').resizable({
    resize: function() {
      editor.setSize();
      editor.refresh();
    },
    minHeight: $textArea.height(),
    minWidth: $textArea.width(),
    maxWidth: $textArea.width()
  });
};

