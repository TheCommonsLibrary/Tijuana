/*
 * Appends the tracking token (if available) to all links to getup.org.au. The
 * script will only work if jquery is available.
 */

(function($){

  // Exit if jquery is not available
  if (!$) { return; }

  // Extract a paramater from the current query string. Handle improperly
  // esacped getup tokens i.e with equals signs in them
  function getURLParam(sParam){
    var sPageURL = window.location.search.substring(1);
    var sURLVariables = sPageURL.split('&');
    var keyAndValue, indexOfEquals, key, value;
    for (var i = 0; i < sURLVariables.length; i++) {
      keyAndValue = sURLVariables[i];
      indexOfEquals = keyAndValue.indexOf('=');
      if (indexOfEquals > -1) {
        key = keyAndValue.substring(0, indexOfEquals);
        value = keyAndValue.substring(indexOfEquals + 1).replace(/\//g, '');
        if (key === sParam){
          return value;
        }
      }
    }
	}

  // On load, append the token to all getup links
  $(function(){
    var token = getURLParam('t');

    // Exit if the token is not available
    if (!token) { return; }

    $('a[href]').each(function(){
      var $a = $(this);
      var link = $a.attr('href');
      // Look for links to getup.org.au
      if (link && link.match(/getup\.org\.au/)){
        if (link.match(/[\?\&]t=/)){
          link = link.replace(/t=(\w+)/, 't=' + token);
        }else{
          if (link.match(/\?/)){
            link += '&';
          }else{
            link += '?';
          }
          link += 't=' + token;
        }
        $a.attr('href', link);
      }
    });
  });

})($);
