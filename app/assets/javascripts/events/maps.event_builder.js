getup.maps.event_builder = (function () {
  var event_builder = Object.create(getup.maps.event);

  event_builder.disable_details = function () {
    this.scope.find("fieldset.event-details").css({"display": "none"});
  };

  event_builder.enable_details = function () {
    this.scope.find("fieldset.event-details").css({"display": "block"});
  };

  event_builder.remove_verify_button = function () {
    this.scope.find("input.verify").remove();
  };

  event_builder.add_verify_button = function () {
      var _this = this, verify_button;
      if (_this.scope.find("input.verify").size() === 0) {
        verify_button = jQuery("<input type='button' class='verify events-button btn btn-large btn-primary' value=\"Next &gt;&gt;\">");
        verify_button.click(function () {
          _this.verify_address();
        });
      }
    _this.display_verify_button_node.append(verify_button);
  };

  event_builder.add_lookup_button = function () {
    var _this = this,
    lookup_button = jQuery("<input type='button' class='events-button btn btn-large' value='lookup address'>");
    this.lookup_button = lookup_button;
    lookup_button.click(function () {
      _this.lookup_address(_this.scope.find("#event_address").val().replace(/\n/, " ") + " Australia");
      return false;
    });
    this.display_lookup_button_node.append(lookup_button);
    return lookup_button;
  };

  event_builder.bind_to_node = function (scope) {
    var _this = this;
    this.scope = scope;
    this.add_lookup_button();
    if (jQuery("#event_address_latitude").val() === "") {
      this.disable_details();
    }
    jQuery("#event_address").change(function () {
      _this.remove_verify_button();
      _this.disable_details();
      _this.hide_address();
    });
    this.sync();
  };

  event_builder.verify_address = function () {
    this.scope.find("#event_address").val(this.selected_location_string);
    this.enable_details();
    this.scope.tabs("select",1);
  };

  event_builder.render = function (nodes) {
     for (var i = 0; i != nodes.length; i++) {
       switch (nodes[i].title) {
         case "address_latitude":
           this.scope.find("input#event_address_latitude").val(nodes[i].value);
           break;
         case "address_longitude":
           this.scope.find("input#event_address_longitude").val(nodes[i].value);
           break;
         case "suburb_latitude":
           this.scope.find("input#event_suburb_latitude").val(nodes[i].value);
           break;
         case "suburb_longitude":
           this.scope.find("input#event_suburb_longitude").val(nodes[i].value);
           break;
         case "postcode":
           this.scope.find("input#event_postcode").val(nodes[i].value);
           break;
         case "street":
           this.scope.find("input#event_street").val(nodes[i].value);
           break;
         case "suburb":
           this.scope.find("input#event_suburb").val(nodes[i].value);
         break;
       }
     }
  };

  event_builder.sync = function () {
     if (this.scope.find("input#event_address_latitude").val() !== "") {
       this.lookup_address(this.scope.find("#event_address").text().replace(/\n/, "") + " Australia");
       this.enable_details();
     }
  };

  return event_builder;
}());
