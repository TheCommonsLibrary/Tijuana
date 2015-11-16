function TalkingPoints() {
    return {
        enable: function(targetSelector) {
            var newLiner = function(nearby2Chars, nearbyTextLength) {
              if (nearbyTextLength === 0 || nearby2Chars == "\n\n") {
                return "";
              } else if (nearby2Chars.indexOf("\n") > 0) {
                return "\n";
              } else {
                return "\n\n";
              }
            };

            $('.talking-points input.btn').click(function(){
                var target = $(targetSelector);
                var selectionStart = target.prop('selectionStart');
                var selectionEnd = target.prop('selectionEnd');
                var existingText = target.val();
                var textBeforeSelection = existingText.substring(0, selectionStart);
                var textAfterSelection = existingText.substring(selectionEnd);
                var leadingLine = newLiner(textBeforeSelection.slice(-2), textBeforeSelection.length);
                var trailingLine = newLiner(textAfterSelection.slice(0, 2), textAfterSelection.length);
                var textToInsert = leadingLine + $.trim($(this).data('text')) + trailingLine;
                target.val(textBeforeSelection + textToInsert + textAfterSelection);
                target.prop('selectionStart', selectionStart + textToInsert.length);
                target.prop('selectionEnd', selectionStart + textToInsert.length);
                $(this).focus();
            });
        }
    };
}
