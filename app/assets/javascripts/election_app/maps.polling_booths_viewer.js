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
        event.htv_links = $.map(event.electorates, function(name){
          var convertedName = name.toLowerCase().replace(/ /, '_');
          return {name: name, link: '/vote/' + convertedName + '?b=' + event.id};
        });
        _this.current_markers.push(_this.marker_factory({add: {
         map: _this.map,
         order: event.order,
         position: _this.location_to_latlng(event.geo),
         title: event.name,
         category: event.category,
         content: _this.template_provider(_this.event_info_template, event).replace("is <strong>ended</strong>", "has <strong>ended</strong>"),
         status: event.status
        }}));
    });
    
  };
  
  event_viewer.list_search_results = function(events) {
    var _this = this;
    $("#local-search-results ul").empty();
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
    args.format = 'json';
    jQuery.getJSON(this.geo_source, args, fn);
  };

  event_viewer.find_by_postcode = function (origin_postcode, search_radius, gt_active, gt_admin_managed) {
    var _this = this;
    _this.show_spinner();
    _this.geodata(
      function (response) {
        if (response.all.length > 0) {
          _this.render_markers(response.all);
          _this.save_events(response.all);
          _this.list_search_results(response.all);
          _this.zoom_all_markers();
          _this.too_many_results(response.all.length >= MAX_SEARCH_RESULTS);

          // update global bestGuessVotingLocation after postcode search
          var closestBooth = response.all[0].geo;
          bestGuessVotingLocation.set(closestBooth.lat, closestBooth.lng);

        } else {
          $('<div>No polling booths found. Try another postcode.</div>').prependTo($("body")).dialog({
            autoOpen: true,
            draggable: false,
            resizable: false,
            zIndex: 1000,
            modal: true,
            buttons: {
              "Ok": function() { $(this).dialog("close"); }
          }});
        }
        _this.hide_spinner();
      },
      { origin_postcode: origin_postcode, search_radius: search_radius, limit: MAX_SEARCH_RESULTS }
    );
  };
  
  event_viewer.display_events = function (search_args) {
    var _this = this;
    _this.geodata(function (response) {
      _this.show_map();
      if (response.all.length > 0) {
        _this.render_markers(response.all);
        _this.save_events(response.all);
        if (_this.current_markers.length == 1) {
          _this.center_on_location({ center: _this.current_markers[0].position , zoom: SUBURB_ZOOM });
        } else {
            _this.zoom_all_markers();
        }
      }
      _this.hide_spinner();
    }, search_args);
  };

  event_viewer.bind_to_node = function (scope, gt_active, gt_admin_managed) {
    var _this = this;
    this.scope = scope;
    this.scope.find("form#search-in-events").submit(function () {
      document.activeElement.blur();

      // pad with leading zero if postcode is 0200, 0800, 0900.
      // used for iOS devices that trim leading zeros in input type=number
      var postcode = _this.scope.find("#origin-postcode").val();
      if (postcode.match(/^[2,8,9]\d\d$/)) {
        postcode = "0" + postcode;
      }

      _this.find_by_postcode(postcode, _this.scope.find("#search-radius").val(), gt_active, gt_admin_managed);
      return false;
    });
  };

  event_viewer.get_current_location = function(map, position) {
    var markerOpts = {
      map: map,
      position: position,
      animation: google.maps.Animation.DROP, 
      title: "Current Location",
      clickable: false,
      cursor: 'pointer',
      draggable: false,
      flat: true,
      icon: {
          'url': 'https://google-maps-utility-library-v3.googlecode.com/svn/trunk/geolocationmarker/images/gpsloc.png',
          'size': new google.maps.Size(34, 34),
          'scaledSize': new google.maps.Size(17, 17),
          'origin': new google.maps.Point(0, 0),
          'anchor': new google.maps.Point(8, 8)
      },
      // This marker may move frequently - don't force canvas tile redraw
      optimized: false, 
      zIndex: 2
    };
    return new google.maps.Marker(markerOpts);
  };
  
  event_viewer.zoom_all_markers = function () {
    var _this = this, bounds = new google.maps.LatLngBounds(), currentLatLng;

    if (_this.showCurrentLocation && _this.currentLocation) {
      if (_this.current_location_marker) {
          _this.marker_factory({remove: {
              'marker': _this.current_location_marker
          }});
      }
      currentLatLng = new google.maps.LatLng(_this.currentLocation.coords.latitude, _this.currentLocation.coords.longitude);
      _this.current_location_marker = _this.get_current_location(_this.map, currentLatLng);
    }

    jQuery.each(_this.current_markers, function (index, marker) {
      bounds.extend(marker.position);
    });
    _this.map.fitBounds(bounds);
  };

    event_viewer.get_and_display_events = function() {
      var _this = this;
      _this.show_spinner();
      if((typeof preApprovedGeolocation != 'undefined') && !preApprovedGeolocation) {
        _this.display_events({});
      }
      if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(function (position) {
                _this.currentLocation = position;
                _this.display_location_map_node.trigger('current-position', position);
                _this.display_events({latitude: position.coords.latitude, longitude: position.coords.longitude, limit: MAX_SEARCH_RESULTS});
            },
            function () {
                _this.display_location_map_node.trigger('no-current-position');
                _this.display_events({});
            }
        );
      } else {
          _this.display_location_map_node.trigger('no-current-position');
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

function makePostcodeSearchAndroidFriendly() {
  var navigatorUserAgentNotSupported = typeof navigator.userAgent === 'undefined';
  var isAndroid = navigator.userAgent.toLowerCase().indexOf("android") > -1;
  var isChrome = navigator.userAgent.toLowerCase().indexOf("chrome") > -1;

  if ( navigatorUserAgentNotSupported || (isAndroid && ! isChrome) ) {
    $('#origin-postcode').clone().attr('type','text').insertAfter('#origin-postcode').prev().remove();
  }
}
