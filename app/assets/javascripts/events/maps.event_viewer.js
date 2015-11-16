getup.maps.event_viewer = (function () {
  var event_viewer = Object.create(getup.maps.event),
      MAX_ZOOM = 0,
      SUBURB_ZOOM = 14,
      MAX_SEARCH_RESULTS = 20;

  event_viewer.too_many_results = function(b) {
    if (b) {
        $("#local-search-results .too-many-results").show();
    } else {
        $("#local-search-results .too-many-results").hide();
    }
  };

  event_viewer.render_markers = function (events) {
    var _this = this;
    _this.remove_all_markers();

    jQuery.each(events, function (index, event) {
        _this.current_markers.push(_this.marker_factory({add: {
         map: _this.map,
         order: event.order,
         position: _this.location_to_latlng(event.geo),
         title: event.name,
         content: _this.template_provider(_this.event_info_template, event).replace("is <strong>ended</strong>", "has <strong>ended</strong>"),
         status: event.status
        }}));
    });

  };

  event_viewer.list_search_results = function(events) {
    var _this = this;
    $("#local-search-results ul").empty();
    $(".get-together-sidebar-content").empty();
	jQuery.each(events, function (index, event) {
      var event_li = $(_this.template_provider(_this.event_results_template, event));
      $("#local-search-results ul").append(event_li);
      event_li.children(".event-center").click(function() {
        _this.center_on_location( _this.location_to_latlng(event.geo) );
        _this.info_window.maxWidth = 250;
        _this.info_window.setContent(_this.template_provider(_this.event_info_template, event).replace("is <strong>ended</strong>", "has <strong>ended</strong>"));
        _this.info_window.open(_this.map, _this.current_markers[index]);
      });
    });
    $("#local-search-results").show();
  };

  event_viewer.geodata = function (fn, args) {
    jQuery.getJSON(this.geo_source, args, fn);
  };

  event_viewer.find_by_postcode = function (origin_postcode, search_radius, gt_active, gt_admin_managed) {
    var _this = this;
    _this.show_spinner();
    _this.geodata(
      function (response) {
        if (response.all.length > 0) {
          _this.render_markers(response.all);
          _this.list_search_results(response.all);
          _this.zoom_map();
          _this.too_many_results(response.all.length >= MAX_SEARCH_RESULTS);
        } else if(!gt_active || gt_admin_managed) {
          $('<div>There were no events found within a ' + search_radius + 'km radius. Please broaden your search.</div>').prependTo($("body")).dialog({
            autoOpen: true,
            title: "No events found",
            draggable: false,
            resizable: false,
            zIndex: 1000,
            buttons: {
              "Ok": function() { $(this).dialog("close"); }
          }});
        } else {
          $('<div>There were no events found within a ' + search_radius + 'km radius.  Why don\'t you host your own?</div>').prependTo($("body")).dialog({
            autoOpen: true,
            title: "No events found",
            draggable: false,
            resizable: false,
            zIndex: 1000,
            buttons: {
              "Host my own": function() { window.location = $("#create-event").attr("href"); },
              "No thanks": function() { $(this).dialog("close"); }
          }});
        }
        _this.hide_spinner();
      },
      { origin_postcode: origin_postcode, search_radius: search_radius, limit: MAX_SEARCH_RESULTS }
    );
  };

  event_viewer.zoom_map = function() {
      var _this = this;
      if (_this.current_markers.length == 1) {
          _this.center_on_location({ center: _this.current_markers[0].position , zoom: SUBURB_ZOOM });
      } else {
          _this.zoom_all_markers();
      }
  };

  event_viewer.display_events = function (search_args) {
    var _this = this;
    _this.geodata(function (response) {
      _this.show_map();
      if (response.all.length > 0) {
        _this.render_markers(response.all);
        _this.zoom_map();
      }
      _this.hide_spinner();
    }, search_args);
    _this.show_map();
  };

  event_viewer.bind_to_node = function (scope, gt_active, gt_admin_managed) {
    var _this = this;
    this.scope = scope;
    this.scope.find("form#search-in-events").submit(function () {
      _this.find_by_postcode(_this.scope.find("#origin-postcode").val(),_this.scope.find("#search-radius").val(), gt_active, gt_admin_managed);
      return false;
    });
  };

  event_viewer.zoom_all_markers = function () {
    var _this = this, bounds = new google.maps.LatLngBounds();
    jQuery.each(_this.current_markers, function (index, marker) {
      bounds.extend(marker.position);
    });
    _this.map.fitBounds(bounds);
  };

    event_viewer.get_and_display_events = function() {
      var _this = this;
      _this.show_spinner();
      _this.display_events({});
      if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(function (position) {
                _this.display_events({latitude: position.coords.latitude, longitude: position.coords.longitude, limit: MAX_SEARCH_RESULTS});
            },
            function () {
                _this.display_events({});
            },
            { timeout: 1500, maximumAge: 60000 }
        );
      } else {
        _this.display_events({});
      }
    };

event_viewer.show_spinner = function() {
  $('.loading').show().spin();
};

event_viewer.hide_spinner = function() {
  $('.loading').hide();
};

  return event_viewer;
}());


