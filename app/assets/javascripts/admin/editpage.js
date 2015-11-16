var pageEditing = function() {

  function countTellAFriends() {
    var tellAFriendCount = 0;
    $('.module').each(function(i, module) {
      if ($(module).attr('class').indexOf('tell_a_friend') != -1) {
        tellAFriendCount += 1; 
      }
    }); 
    return tellAFriendCount;
  }

  function hideTellAFriendWhenOneExists() {
    if (countTellAFriends() === 0) {
      $(".add-tell-a-friend-button").fadeIn(); 
    } else {
      $(".add-tell-a-friend-button").fadeOut();    
    }
  }

  function hideStandfirstModuleWhenOneExists() {
      var standfirstModuleCount = 0;
      $('.module').each(function(i, module) {
          if ($(module).attr('class').indexOf('standfirst_module') != -1) {
              standfirstModuleCount += 1;
          }
      });

      if (standfirstModuleCount === 0) {
          $("a.standfirst_module").fadeIn();
      } else {
          $("a.standfirst_module").fadeOut();
      }
  }

  function newModuleAddedToPage(modulesList, data) {
    var moduleDom = $(data);
    var inlineForms = moduleDom.find("form");
    inlineForms.appendTo("body");
    
    modulesList.append(moduleDom);
    hideTellAFriendWhenOneExists();
    hideStandfirstModuleWhenOneExists();
  }


  var editPage = function() {
    hideTellAFriendWhenOneExists();
    hideStandfirstModuleWhenOneExists();
    
    function moduleAdded(e, data, status, xhr) {
      newModuleAddedToPage($(e.target).parents(".layout-container").find('ul[id*="-modules"]'), data);
    }
    
    function toggleThankyouEmailDetails() {
      if ($("#page_send_thankyou_email").attr("checked")) {
        $("#thankyou-email-details").slideDown("fast");
      } else {
        $("#thankyou-email-details").slideUp("fast");      
      }
    }
    
    $('.add-module-link').bind("ajax:success", moduleAdded);
    displayThrobber('.add-module-link');
    
    $("#page_send_thankyou_email").change(toggleThankyouEmailDetails);
    if (!$("#page_send_thankyou_email").attr("checked")) {
      $("#thankyou-email-details").hide();
    }
  };



  var contentModule = function(content_module_id) {  
    function moduleRemoved(e, data, status, xhr) {
      module.remove();
      hideTellAFriendWhenOneExists();
      hideStandfirstModuleWhenOneExists();
    }
    
    function moduleAppended(e, data, status, xhr) { 
      var targetContainer = moduleSwitcher.parents('.layout-container').siblings('.layout-container');
      targetContainer.find('ul').append(module);
      if (targetContainer.attr('id') == 'main_content') {
        moduleSwitcher.text('Move to sidebar');
      } else {
        moduleSwitcher.text('Move to main content');
      }
      module.effect('highlight');
    }
    
    function moduleUnlinked(e, data, status, xhr) {
      newModule = $(data);
      module.replaceWith(newModule);
      newModule.effect('highlight');
    }
    
    function unlockEditing() {
      fields.removeAttr("disabled");
      unlockEditingLink.fadeOut();
      module.effect('highlight');
    }

    var module = $("#content_module_" + content_module_id);
    var fields = module.find("input,select,textarea");
    var linkControls = module.find(".link-controls");
    var moduleSwitcher = $("#switch-container-" + content_module_id);
    var removeLink = $("#remove-module-" + content_module_id);
    var unlockEditingLink = module.find(".unlock-editing");
    var unlinkModuleLink = module.find(".unlink-module");
   
    removeLink.bind("ajax:success", moduleRemoved);
    moduleSwitcher.bind("ajax:success", moduleAppended);
    unlinkModuleLink.bind("ajax:success", moduleUnlinked);
    unlockEditingLink.click(unlockEditing);


    if (module.parents(".layout-container").find(".unlock-sorting").is(':visible')) {
       module.find(".handle").hide();
    }
    
    if (unlockEditingLink.is(':visible')) {
       fields.attr("disabled", "disabled");
    }
  };

  var bookmarkableModule = function(content_module_id, bookmark_url) {
    function showBookmarkForm() {
      bookmarkForm.css("left", bookmarkLink.offset().left - 270 + "px");
      bookmarkForm.css("top", bookmarkLink.offset().top + 7 + "px");
      bookmarkForm.fadeIn('fast');
      return false; 
    } 
    
    function hideBookmarkForm() {
      bookmarkForm.fadeOut('fast');
      nameField.val("");
      errorContainer.empty();
      return false; 
    }

    function unbookmarked(data, status, xhr) {
      bookmarkLink.show();
      unbookmarkLink.hide();
    }
    
    function handleResponse(xhr, status) {
      if (status == "error") {
        errorContainer.text(xhr.responseText);
      } else {
        hideBookmarkForm();
        bookmarkLink.hide();
        unbookmarkLink.show();
      }
    }
    
    function submitBookmarkForm() {
      var data = {
        content_module_id: content_module_id,
        bookmark_name: nameField.val()
      };
      
      $.ajax({
        url: bookmark_url,
        dataType: 'json',
        data: data,
        complete: handleResponse
      });
      
      return false;
    }
    
    var bookmarkLink = $("#bookmark-module-" + content_module_id);
    bookmarkLink.bind("click", showBookmarkForm);
      
    var unbookmarkLink = $("#unbookmark-module-" + content_module_id);
    unbookmarkLink.bind("ajax:success", unbookmarked);

    var bookmarkForm = $("#bookmark-form-" + content_module_id);
    bookmarkForm.submit(submitBookmarkForm);
    
    var nameField = bookmarkForm.find("input[name=bookmark_name]");
    var errorContainer = bookmarkForm.find(".error");
    
    var cancelLink = bookmarkForm.find(".cancel");
    cancelLink.click(hideBookmarkForm);
  };


  var addFromBookmarks = function(bookmarksListSelector, modulesListSelector) {
    function moduleAdded(e, data, status, xhr) {
      $.colorbox.close();
      newModuleAddedToPage($(modulesListSelector), data);
    }
    
    var list = $(bookmarksListSelector);  
    list.find("a").bind("ajax:success", moduleAdded);
  };
  return {
    setupContentModule: contentModule,
    setupEditPage: editPage,
    setupBookmarkableModule: bookmarkableModule,
    setupAddFromBookmarks: addFromBookmarks
  };
};




