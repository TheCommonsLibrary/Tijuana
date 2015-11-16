var getShortenedContent = function(content, maxLength) {

  var removeLeadingBrTags = function(items) {
    var item = items[0];
    if (item && item.is('br')) {
      items.shift();
      removeLeadingBrTags(items);
    }
  };

  var removeTrailingBrTags = function(items) {
    var item = items[items.length-1];
    if (item && item.is('br')) {
      items.pop();
      removeTrailingBrTags(items);
    }
  };

  var rewriteAccordions = function(elements) {
    $(".accordion-body", elements).each(function(i, e) {
      var id = $(e).attr('id');
      var newId = id + "-standfirst";
      $("a[href='#" + id + "']", elements).attr('href', "#" + newId);
      $(e).attr("id", newId);
    });
  };

  var elements = content.clone(),
      currentTextLength = 0,
      items = [];

  rewriteAccordions(elements);

  for(var i = 0; i < elements.contents().length; i++) {
    var item = $(elements.contents()[i]);

    if(!item.is('script')) {
      var text = item.text().trim();
      if (text !== "" || item.is('br')) {
        items.push(item);
        currentTextLength += text.length;
        if (currentTextLength > maxLength) {
          break;
        }
      }
    }
  }
  removeLeadingBrTags(items);
  removeTrailingBrTags(items);
  
  return items;
};

jQuery(function ($) {

  var enableReadMoreClasses =  function() {
    $('.main-content').toggleClass("main-content main-content-responsive");
  };

  var addReadMoreButton = function() { 
    var button = $("<a class='readmore btn btn-min'>Read More</a>");
    button.insertAfter($('.standfirst-module'));
    button.click(function() {
      $('.main-content-responsive').slideDown();
      $('.standfirst-module.generated').hide();
      button.hide();
    }); 
  };

  var generateAutoStandfirst = function() {
    var truncated = getShortenedContent($('.main-content-responsive'), 150);
    var wrapped = $("<div class='standfirst-module generated'></div>").append(truncated);
    $(".container article h1").first().after(wrapped);
  };
  if (!tijuana.readMoreDisabled && $('.standfirst-module, body.campaign').length) {
    enableReadMoreClasses();
    if(!$('.standfirst-module').length) {
      generateAutoStandfirst();
    }
    addReadMoreButton();
  }
});

