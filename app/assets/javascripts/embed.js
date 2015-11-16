/*
 * Embed a Tijuna page. It will only work if jquery is available.
 */

(function($){
  // Exit if jquery is not available
  if (!$) { return; }
  var $script = $('script[data-container]');

  var script = document.createElement('script');
  script.type = "text/javascript";
  if(script.readyState) {  //IE
    script.onreadystatechange = function() {
      if ( script.readyState === 'loaded' || script.readyState === 'complete'  ) {
        script.onreadystatechange = null;
        resizerLoaded();
      }
    };
  } else {  //Others
    script.onload = function() {
      resizerLoaded();
    };
  }
  script.src = 'https://d68ej2dhhub09.cloudfront.net/scripts/iframeResizer.min.js';
  document.getElementsByTagName('head')[0].appendChild(script);

  function resizerLoaded() {
    if (!$script.length) { return; }
    var $container = $('#' + $script.data('container'));

    var url = $script.data('url');
    var token = getURLParam('t');
    var iframe = document.createElement('iframe');
    if (token) {
      url += (url.match(/\?/) ? '&' : '?') + 't=' + token;
    }
    iframe.setAttribute('id', 'gu-embed');
    iframe.setAttribute('src', url);
    iframe.setAttribute('frameborder', '0');
    iframe.setAttribute('style', 'width:100%;');
    iframe.setAttribute('allowtransparency', 'true');
    if ($script.data('stylesheet')) {
      iframe.setAttribute('name', $script.data('stylesheet'));
    }
    $container.append(iframe);
    $('#gu-embed').iFrameResize({checkOrigin: false});
    if (window.postMessage && $script.data('handler')){
      window.addEventListener("message", window[$script.data('handler')], false);
    }
  }

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
})($);
