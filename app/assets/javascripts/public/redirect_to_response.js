/* Clicks on elements with listenClass will post to the 'not you' path and redirect to the returned url. */
function notYou(listenClass, path, pageId, token) {
  $(listenClass).click(function(ev) {
    ev.preventDefault();
    $.post(path, {page_id: pageId, t: token}, function(data) {
      window.location = data.url;
    });
  });
}
