/*global window, $, jQuery, document */
var getup = window.getup || { };

getup.geo = {
  user: function (options) {
    options.locator.getCurrentPosition(function (position) {
      options.map[options.location_property] = {
        lat: position.coords.latitude,
        lng: position.coords.longitude
      };
      options.map.center_for_user();
    }, function () {
      options.map[options.location_property] =  null;
    });
  },

  showDirections: function(from, to) {
    window.open( 'http://maps.google.com/maps?saddr=' + from.latitude + ',' + from.longitude + '&daddr=' + to.latitude + ',' + to.longitude );
  },

  doWithCurrentPosition: function(success, error, locator){
    if(!locator) { locator = navigator.geolocation; }

    if(locator) {
      locator.getCurrentPosition(function(position) {
        success(position.coords);
      }, error);
    } else {
      if(error) {
        return error();
      }
    }
  }
};
