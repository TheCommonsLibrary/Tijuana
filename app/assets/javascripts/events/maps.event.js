/*global window, $, jQuery, document */

if (typeof Object.create !== 'function') {
  Object.create = function (o) {
    function F() {}
    F.prototype = o;
    return new F();
  };
}

var getup = window.getup || { };
getup.maps = {};

getup.maps.event = {

  create: function (deps) {
    var new_map = Object.create(this), dep;
    for (dep in deps) { if (deps.hasOwnProperty(dep)) {
      new_map[dep] = deps[dep];
    } }
    return new_map;
  },

  render: function () { },

  event_info_template: eventMapBubbleTemplate,
  
  event_results_template: eventSearchResultsTemplate,
  
  user_location: null,

  current_markers: [],

  lookup_button: null,

  geo_bounds: function () {
    var south_west = new google.maps.LatLng(-42.730874,156.665039),
        north_east = new google.maps.LatLng(-10.477009,117.37793);

    return new google.maps.LatLngBounds(south_west, north_east);
  },

  lookup_geo: function (geo) {
    var _this = this,
        lookup = {address: geo.address};
    if (_this.geo_bounds()) {
      lookup.bounds = _this.geo_bounds();
    }
    this.geocoder.geocode(lookup, function (results, status) {
      if (status === _this.geocoder_status_codes.OK) {
        geo.success(results);
      } else {
        geo.failure(results);
      }
    });
  },
  
  center_on_viewport: function (address) {
    this.geocoder.geocode({ "address": address }, function (results, status) {
      if (status === this.geocoder_status_codes.OK) {
        this.map.fitBounds(results[0].geometry.viewport);
      }
    });
  },

  center_for_user: function () {
    if (this.map && this.current_markers.length > 1) {
      this.map.setCenter(this.location_to_latlng(this.user_location));
    }
  },

  disable_lookup_button: function(disabledText) {
    this.lookup_button.attr('disabled', 'disabled');
    this.lookup_button.attr('value', disabledText);
  },

  enable_lookup_button: function(enabledText) {
    this.lookup_button.removeAttr('disabled');
    this.lookup_button.attr('value', enabledText);
  },

  lookup_address: function (address) {
    var _this = this;
    var originalButtonText = this.lookup_button.val();
    _this.disable_lookup_button('please wait...');
    this.lookup_geo({
      address: address.replace(/[\n]/gim, " ").replace(/[\s]+/gim, " "),
      success: function (results) {
        _this.show_address(results);
        _this.enable_lookup_button(originalButtonText);
      },
      failure: function (results) {
        _this.display_location_text_node.html("<p>Address could not be found</p>");
        _this.enable_lookup_button(originalButtonText);
      }
    });
  },

  remove_markers: function (address) {
    var _this = this;
    if (this.current_markers) {
      jQuery.each(this.current_markers, function (index, marker) {
        if (marker) {
          _this.marker_factory({remove: {marker: marker}});
        }
      });
    }
    this.current_markers = [];
  },

  location_to_string: function (location) {
    if (location && location.lat && location.lng) {
      return "(" + location.lat() + "," + location.lng() + ")";
    } else { return null; }
  },
  
  location_to_latlng: function (location) {
    var lat = location.lat*1, lng = location.lng*1;
    if (isNaN(lng)) {
      lng = location.lng();
    }
    if (isNaN(lat)) {
      lat = location.lat();
    }
    return new google.maps.LatLng(lat, lng);
  },

  reverse_lookup: function () {
    // gets called when we hit the radio button to choose address, after look up
    // json response format: https://developers.google.com/maps/documentation/geocoding/
    var _this = this, i, j, postcode = "Unknown", street = "Unknown", suburb = "Unknown";
     _this.geocoder.geocode({
      latLng: _this.selected_location}, function (results, status) {
        if (status == _this.geocoder_status_codes.OK) {
          for (i = 0; i !== results.length; i++) {
            if (results[i].geometry.location_type === "ROOFTOP" ||
                results[i].geometry.location_type === "RANGE_INTERPOLATED" ) {
              for (j = 0; j !== results[i].address_components.length; j++) {
                if (jQuery.inArray("postal_code", results[i].address_components[j].types) >= 0) {
                  postcode = results[i].address_components[j].long_name;
                } else if (jQuery.inArray("route", results[i].address_components[j].types) >= 0) {
                  street = results[i].address_components[j].long_name;
                } else if (jQuery.inArray("locality", results[i].address_components[j].types) >= 0) {
                  suburb = results[i].address_components[j].long_name;
                }
              }
              _this.render([{
                "title": "postcode",
                "value": postcode
              },
              {
                "title": "street",
                "value": street
              },
              {
                "title": "suburb",
                "value": suburb
              }]);
            }
            if (results[i].geometry.location_type === "APPROXIMATE") {
              for (j = 0; j !== results[i].address_components.length; j++) {
                if (jQuery.inArray("postal_code", results[i].address_components[j].types) >= 0) {
                  postcode = results[i].address_components[j].long_name;
                } else if (jQuery.inArray("locality", results[i].address_components[j].types) >= 0) {
                  suburb = results[i].address_components[j].long_name;
                }
              }
              _this.render([{
                "title": "suburb_latitude",
                "value": results[i].geometry.location.lat()
              },
              {
                "title": "suburb_longitude",
                "value": results[i].geometry.location.lng()
              },
              {
                "title": "postcode",
                "value": postcode
              },
              {
                "title": "suburb",
                "value": suburb
              }]);
              break;
            }
          }
        }
    });
  },

  select_location: function (result) {
    var _this = this, i;
    _this.selected_location = result.geometry.location;
    _this.selected_location_string = result.formatted_address;
    _this.map.setCenter(_this.selected_location);
    _this.render([{
      "title": "address_latitude",
      "value": _this.selected_location.lat()
      },
      {
      "title": "address_longitude",
      "value": _this.selected_location.lng()
    }]);
    _this.reverse_lookup();

    if (_this.clashing_event_detector) {
        _this.clashing_event_detector(result.geometry.location.lat(), result.geometry.location.lng(), function(clash){
            if (clash) {
                _this.remove_verify_button();
                if (confirm("We're really excited that you want to be a part of this event, but rather than hosting your own event in this area, there's another one nearby that we would love you to join us at. Click OK to see the details and RSVP to your nearest event.")) {
                    window.location = clash;
                }
            } else {
                _this.add_verify_button();
            }
        });
    } else {
        _this.add_verify_button();
    }
  },

  active_addresses: function (results) {
    var ul = jQuery("<ul class='map-addresses'></ul>"),
        _this = this;

    jQuery.each(results, function (index, result) {
       var address_li = jQuery("<li><input type=\"radio\" name=\"location\"/><a href=\"#\" onclick=\"return false;\">" + result.formatted_address + "</a></li>");
       (function () {
         var _result = result;
         address_li.click(function() {
           _this.select_location(_result);
           ul.find("li").removeClass("active");
           jQuery(this).addClass("active");
           jQuery(this).find("input[type=\"radio\"]").attr("checked", true);
         });
       }());
       ul.append(address_li);
    });
    return ul;
  },

  show_map: function (options) {
    options = options || {};
    var _this = this, defaults = { center: options.center || _this.location_to_latlng({ lat: -25.2743980, lng: 133.7751360 }), zoom: options.zoom || 3, maxZoom: this.maxZoom || 0, mapTypeId: _this.map_type || "ROADMAP" };
    if (!_this.map) {
      this.map = _this.map_factory(_this.display_location_map_node.get(0), defaults);
      if (options.center) {
        _this.center_on_location(options);
      }
    }
  },

  center_on_location: function (options) {
    this.map.setCenter(options.center);
    if (options.zoom) {
      this.map.setZoom(options.zoom);
    }
  },

  hide_address: function () {
    var _this = this;
    _this.remove_markers();
    _this.display_location_text_node.empty();
    _this.display_location_text_node.html("");
  },

  show_address: function (results, options) {
    var _this = this;
    _this.remove_markers();
    _this.display_location_text_node.empty();
    _this.show_map({zoom: 15, center: results[0].geometry.location});
    jQuery.each(results, function (index, result) {
      _this.current_markers.push(_this.marker_factory({add: {
        map: _this.map,
        position: result.geometry.location,
        title: result.formatted_address,
        content: _this.template_provider(_this.event_info_template, result).replace("is <strong>ended</strong>", "has <strong>ended</strong>"),
        status: result.status
      }}));
    });
    _this.display_location_text_node.html("<p class='event-decorate-text'>Please select the correct address:</p>").append(_this.active_addresses(results));
  },
  
  remove_all_markers: function() {
    var _this = this;
    jQuery.each(_this.current_markers, function (index, marker) {
       _this.marker_factory({remove: {
         'marker': marker
       }});
    });
    _this.current_markers = [];
  },

  api_key: "",
  geocoder: null,
  map: null,
  map_factory: null,
  marker_factory: null,
  display_location_map_node: null,
  display_location_text_node: null,
  display_lookup_button_node: null,
  display_verify_button_node: null,
  geocoder_status_codes: {},
  map_type: null
};
