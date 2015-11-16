
xdescribe("getup.maps event viewer", function () {
  beforeEach(function () {
    jasmine.getFixtures().load("maps_view.html");
    maps = getup.maps.event_viewer.create();
    maps.geo_bounds = function () { return null; };
    maps.template_provider = function () { return ""; },
    maps.map_factory = function () {
      return {setCenter: function() {}};
    };
    maps.marker_factory = function () {};
    maps.display_location_map_node = jQuery("get-together-events-map");
    maps.location_to_latlng = function () {
      return {lat: function () { return 2; }, lng: function () { return 5; } };
    };
    maps.geo_source = "#";
    mock_geodata = {
      "all": [
        {
          "name": "test event 1",
          "geo": {
            "lat": "-33.8630258",
            "lng": "151.2090263"
          },
          "postcode": "",
          "capacity": "34",
          "phone": "2222222",
          "date": "2011-04-30"
        }
        ,
        {
          "name": "test event 2",
          "geo": {
            "lat": "-33.7328193",
            "lng": "151.00495990000002"
          },
          "postcode": "9999",
          "capacity": "3453",
          "phone": "212312314",
          "date": "2011-04-30"
        }
      ]
    };

  });



  describe("display events", function () {
    beforeEach(function () {
      zoom_all_markers = false;
      get_json_called = false;
      maps.geodata = function(fn, args) {
        get_json_called = true;
        zoom_all_markers = true;
        fn(mock_geodata);
      };
    });

    xit("should dispatch an ajax request for geolocation data", function () {
      maps.display_events();
      expect(get_json_called).toBe(true);
    });

    xit("should request a marker for each event", function () {
      var calls = 0;
      maps.marker_factory = function () {
        calls += 1;
      };

      maps.display_events();
      expect(calls).toBe(mock_geodata.all.length);
    });
  });

  describe("center for user", function () {
    it("should center for the user if more than one location is being displayed", function() {
      var called = false;
      maps.current_markers = [{}, {}, {}];
      maps.map = { setCenter: function() { called = true; } };
      maps.center_for_user();
      expect(called).toBe(true);
    });
    it("should not center for the user if only one location is being displayed", function() {
      var called = false;
      maps.current_markers = [{}];
      maps.map = { setCenter: function() { called = true; } };
      maps.center_for_user();
      expect(called).toBe(false);
    });
  });

  describe("find in events", function () {

    xit("should zoom all markers", function () {
      maps.find_by_postcode({ origin_postcode: 2001, search_radius: 5 });
      expect(zoom_all_markers).toBe(true);
    });
  });

  describe("bind to node", function () {
    xit("should bind to the postcode lookup form", function () {
      sinon.stub(maps, "find_by_postcode");
      maps.bind_to_node(jQuery("#event-locations"));
      jQuery("#origin-postcode").val("2230");
      jQuery("#search-radius").val("5");
      jQuery("form#search-in-events").submit();
      expect(maps.find_by_postcode).toHaveBeenCalledWith("2230","5");
    });
  });

});
