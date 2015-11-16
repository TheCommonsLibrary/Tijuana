// This is from underscore.js
var escape_html = function(string) {
  var htmlEscapes = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#x27;',
    '/': '&#x2F;'
  };

  var htmlEscaper = /[&<>"'\/]/g;

  return ('' + string).replace(htmlEscaper, function(match) {
    return htmlEscapes[match];
  });
};