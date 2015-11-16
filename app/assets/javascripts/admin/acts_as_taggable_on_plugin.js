var actsAsTaggableOnPages = function(uiOptions) {
  var $tags = $('.tags');

  var addCallbacksToOptions = function(pageId) {
    var callbacks = {
      'onAddTag' : function(tag) {
        var pageId = this.name.replace('tags-', '');
        $.post('/admin/pages/' + pageId + "/add_tag?tag=" + tag)
          .fail(function(){
            alert('Failed to add tag');
          }
        );
      },
      'onRemoveTag' : function(tag) {
        var pageId = this.name.replace('tags-', '');
        $.post('/admin/pages/' + pageId + "/remove_tag?tag=" + tag)
          .fail(function(){
            alert('Failed to remove tag');
          }
        );
      }
    };
    return $.extend(uiOptions, callbacks);
  };

  var initActsAsTaggableOn = function() {
    $tags.each(function (key, tag) {
      var mergedOptions = addCallbacksToOptions();
      $(tag).tagsInput(mergedOptions);
    });
  };

  var stopClickPropagation = function() {
    $('.tagsinput').each(function(_, element) {
      $(element).click(function(e) {
        e.stopPropagation();
      });
    });
  };

  initActsAsTaggableOn();
  stopClickPropagation();
};