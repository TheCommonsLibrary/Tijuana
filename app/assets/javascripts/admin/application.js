if (typeof Object.create !== 'function') {
    Object.create = function (o) {
        function F() {}
        F.prototype = o;
        return new F();
    };
}

/**
 * Call once at beginning to ensure your app can safely call console.log() and
 * console.dir(), even on browsers that don't support it.  You may not get useful
 * logging on those browers, but at least you won't generate errors.
 * 
 * @param  alertFallback - if 'true', all logs become alerts, if necessary. 
 *   (not usually suitable for production)
 */
/*global console:true */
function fixConsole(alertFallback) {
    if (typeof console === "undefined") {
        console = {}; // define it if it doesn't exist already
    }
    if (typeof console.log === "undefined") {
        if (alertFallback) { console.log = function(msg) { alert(msg); }; } 
        else { console.log = function() {}; }
    }
    if (typeof console.dir === "undefined") {
        if (alertFallback) { 
            // THIS COULD BE IMPROVED… maybe list all the object properties?
            console.dir = function(obj) { alert("DIR: "+obj); }; 
        }
        else { console.dir = function() {}; }
    }
}

// Global helpers to run on every page.
function bigLink(index, container) {
  container = $(container);
  container.css({cursor: 'pointer'});
  container.click(function(ev) {
    if ($.inArray(ev.target.tagName, ["DIV", "LI"]) >= 0) {
      document.location = container.find('a:first').attr('href');
    }
  });
}

function onEveryPage() {
  $('input').livequery(function(){
    $(this).placeholder();
  });

  $('.big-link').each(bigLink);

  $('.error').effect('pulsate');

  fixConsole(false);
}

$(onEveryPage);
var anchorString = self.document.location.hash.substring(1).replace("%20", " ");


document.documentElement.className += ' has-js';

// Workaround for not needing to replace every confirm dialog in the system
// Rails.js will trigger the confirm:complete event so we take the oportunity to save the target element to this variable
// We then use it in the JQuery UI dialog to complete the action in case the user clicks 'Yes'
var targetOfConfirmDialog;

$(document).ready(function () {
  $('a[data-confirm]').live('confirm:complete', function(e, data){
    targetOfConfirmDialog = $(e.target);
  });

  $("body").append("<div id=\"dialog-confirm\" title=\"Confirmation required\"></div>");
  $.rails.confirm = (function () { return customConfirmDialog; }());

  function customConfirmDialog(msg) {
      $("#dialog:ui-dialog").dialog("destroy");
      $("#dialog-confirm").html(msg);
      $("#dialog-confirm").dialog({
        resizable: false,
        modal: true,
        buttons: {
          "Yes": function() {
            //stub confirm function to allow the click to go through
            $.rails.confirm = function () { return true; };
            targetOfConfirmDialog.click();
            //restores it so further confirm dialogs work correctly
            $.rails.confirm = (function () { return customConfirmDialog; }());
            $(this).dialog("close");
          },
          "No": function() {
            $(this).dialog("close");
          }
        }
      });
  }
});
