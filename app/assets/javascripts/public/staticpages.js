function expandingContent(titleSelector, contentSelector) {
  function titleClicked() {
    content.toggle('blind', 'fast');
    title.toggleClass('expanded');
  }

  var content = $(contentSelector);
  var title = $(titleSelector);
  var anchorString = self.document.location.hash.substring(1).replace("%20", " ");

  title.click(titleClicked);
  
  if (anchorString == title.text()) {
    title.toggleClass('expanded');
  } else {
    content.hide(); 
  }
}