function validateHtmlTags(submitBtnSelectors) {
  function runValidation(html){
    var openedTags = [];
    var tag;
    var openedTag;
    var closedTag;
    var tags = parseAllTags(html);

    if (tags.length === 0) {
        return {
          success: true,
          message: ''
        };
    }

    for (var i = 0; i < tags.length; i++) {
      tag = tags[i];
      if (tag.closing) {
        closedTag = tag;

        if (isSelfClosingTag(closedTag.name)) {
          continue;
        }

        if (openedTags.length === 0) {
          return {
            success: false,
            message: 'Closing tag ' + closedTag.tag + ' on line ' + closedTag.line + ' does not have corresponding opening tag.'
          };
        }

        openedTag = openedTags[openedTags.length - 1];
        if (closedTag.name !== openedTag.name) {
          return {
            success: false,
            message: 'Closing tag ' + closedTag.tag + ' on line ' + closedTag.line + ' does not match opening tag ' + openedTag.tag + ' on line ' + openedTag.line + '. Please check your tags are closed in the correct order.'
          };
        } else {
          openedTags.pop();
        }

      } else {
        if (isSelfClosingTag(tag.name)) {
          continue;
        }
        openedTags.push(tag);
      }
    }

    if (openedTags.length > 0) {
      openedTag = openedTags[openedTags.length - 1];
      return {
        success: false,
        message: 'Opening tag ' + openedTag.tag + ' on line ' + openedTag.line + ' does not have a corresponding closing tag.'
      };
    }

    return {
      success: true,
      message:''
    };
  }

  function parseAllTags(html) {
    var tags = [];
    var matches;
    $.each(html.split('\n'), function (i, line) {
      $.each(line.match(/<[^>]*[^\/]>/g) || [], function (j, tag) {
        matches = tag.match(/<\/?([a-z0-9]+)/i);
        if (matches) {
          tags.push({tag: tag, name: matches[1], line: i+1, closing: tag[1] === '/'});
        }
      });
    });

    return tags;
  }

  function isSelfClosingTag(tagName) {
    return tagName.match(/area|base|br|col|embed|hr|img|input|keygen|link|menuitem|meta|param|source|track|wbr|script/i);
  }

  var codeMirrorEditor = $('.CodeMirror')[0].CodeMirror;

  $(submitBtnSelectors).click(function(e){
    var validationResult = runValidation(codeMirrorEditor.getValue());
    if(validationResult.success === false) {
      e.preventDefault();
      $("#tags_validation_result").text("ERROR: " + validationResult.message).effect("highlight");
    }
  });

}
