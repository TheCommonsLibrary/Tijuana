function showModal(modalId) {
  if(window.location.pathname.match(/take_action$/) === null) {
    $(modalId).modal("show");
  } 
}

function sickTaxMap(mapId, actionId, modalContainerId) {

  function addActionToNav(btnText) {
    var btn = $('<a class="btn nav-action-btn" data-target="#action-modal" data-toggle="modal">' + btnText + '</a>');
    $(".navbar .navbar-inner .container").append(btn);
  }

  function addActionToModal() {
    var modal = $('<div id="action-modal" class="modal fade" aria-hidden="true" aria-labelledby="myModalLabel" role="dialog" tabindex="-1"></div>');
    var modalDialog = $('<div class="modal-dialog"></div>');
    var modalContent = $('<div class="modal-content"></div>');
    var modalHeader = $('<div class="modal-header"><button class="close" aria-hidden="true" data-dismiss="modal" type="button"> x </button></div>');
    var modalBody = $('<div class="modal-body"></div>');
    var action = $(actionId);
    var btnText = $(".btn.btn-primary", action).text();
    action.remove();

    modalDialog.append(modalContent);
    modalContent.append(modalHeader);
    modalContent.append(modalBody);
    modal.append(modalDialog);
    modalBody.append(action);
    $(modalContainerId).append(modal);
    addActionToNav(btnText);
  }

  function getName(modal) {
    if($(modal).attr("id") != "action-modal") {
      return $(modal).attr("data-name");
    } else {
      return $("body").attr("id");
    }
  }

  function setupModals() {
    $(".modal").each(function(index, modal) {
      var name = getName(modal);
      var anchor = $("<a></a>").attr({"href": "#", "data-modal-target": $(modal).attr("id")}).html(name);
      var li = $("<li></li>").append(anchor);

      $(anchor).click(function() {
          $(".nav-collapse").collapse('hide');
          var modalId = $(this).attr("data-modal-target");
          $("#"+modalId).modal("show");
      });
      $(".sidebar-nav").append(li);
    });
  }


  function toggleMenuText() {
    if($("#menu-toggle div").text() === '<<') {
      $("#menu-toggle div").text('>>');
    } else {
      $("#menu-toggle div").text('<<');
    }
  }

  function setupSlideMenu() {
    $("#menu-toggle").click(function(e) {
        e.preventDefault();
        $("#wrapper").toggleClass("toggled");
        $("#menu-toggle").toggleClass("toggled");
        toggleMenuText();
    });
  }

  function isMobileView() {
    return document.documentElement.clientWidth <= 767;
  }

  function setupMapKey() {
    var mapKey = $('#map-key');
    if(mapKey.size() === 1) {
      var keyBtn = $("<button id='key-btn' class='btn btn-secondary'>Key</button>");
      keyBtn.click(function() {
        mapKey.toggleClass('show-key');
        keyBtn.toggleClass('hide');
      });

      mapKey.click(function() {
        mapKey.toggleClass('show-key');
        keyBtn.toggleClass('hide');
      });

      mapKey.after(keyBtn);
    }
  }


  var map = $(mapId);
  map.remove();
  $("body").append(map);

  setupModals();
  setupSlideMenu();
  setupMapKey();
  
  if (isMobileView()) {
    addActionToModal();
  }
}
