function bootstrapMap(initialiseWith, variant, apiKey, geoSource, displayLocationMapNode, displayScope, showCurrentLocation, clickViewer) {
    var savedEvents = [];
    window.bootstrap_maps = function () {
        var maps = getup.maps[variant].create({
            showCurrentLocation: showCurrentLocation,
            api_key: apiKey,
            template_provider: Mustache.to_html,
            geo_source: geoSource,
            save_events: function(events){
                savedEvents = events;
            },
            map_factory: function (display_node, options) {
                options.disableDefaultUI = true;
                options.styles = [{featureType: "poi",
                  elementType: "labels",
                  stylers: [{visibility: "off"}]
                }];
                if (initialiseWith) {
                    options.draggable = false;
                    options.disableDoubleClickZoom = true;
                    options.keyboardShortcuts = false;
                    options.scrollwheel = false;
                }
                return new google.maps.Map(display_node, options);
            },
            marker_factory: function (options) {
                var marker,
                    filename,
                    markerStatus,
                    _this = this;
                if (options.add) {
                    marker = new google.maps.Marker({
                        icon: new google.maps.MarkerImage(
                            './images/map-markers/marker.png',
                            new google.maps.Size(20,34),
                            new google.maps.Point(0,0),
                            new google.maps.Point(10,34)),
                        shadow: new google.maps.MarkerImage(
                            'https://www.google.com/intl/en_us/mapfiles/ms/icons/msmarker.shadow.png',
                            new google.maps.Size(59,32),
                            new google.maps.Point(0,0),
                            new google.maps.Point(10,34)),
                        shape: {
                            coord: [55,2,56,3,56,4,56,5,56,6,56,7,56,8,56,9,56,10,56,11,56,12,56,13,56,14,56,15,56,16,56,17,56,18,56,19,56,20,56,21,56,22,56,23,56,24,56,25,56,26,56,27,55,28,33,29,31,30,30,31,28,32,27,33,25,34,24,35,22,36,21,36,21,35,22,34,22,33,23,32,23,31,24,30,24,29,3,28,2,27,2,26,2,25,2,24,2,23,2,22,2,21,2,20,2,19,2,18,2,17,2,16,2,15,2,14,2,13,2,12,2,11,2,10,2,9,2,8,2,7,2,6,2,5,2,4,2,3,4,2,55,2],
                            type: 'poly'
                        },
                        category: options.add.filter,
                        clickable: clickViewer !== null,
                        map: options.add.map,
                        position: options.add.position,
                        title: options.add.title
                    });
                    google.maps.event.addListener(marker, 'click', function() {
                        if (clickViewer) {
                            _this.closeInfoWindow();
                            _this.info_window.maxWidth = 250;
                            $('#polling-booths-info-box button').off('click');
                            _this.info_window.setContent(options.add.content);
                            _this.info_window.open(options.add.map, marker);
                            $('#polling-booths-info-box button, #polling-booths-info-box a').on("click", function(e){
                                e.preventDefault();
                                var link = $(this).data('link');
                                var boothId = link.split('=').pop();
                                var event = savedEvents.find(function(event){ return event.id == boothId; });
                                event.selected_electorate = $(this).data('electorate');
                                if (event.electorates_with_htv[$(this).data('electorate')]){
                                    event.link = link;
                                }
                                return clickViewer(event);
                            });
                        }
                    });
                    return marker;
                } else if (options.remove) {
                    options.remove.marker.setMap(null);
                }
            },
            closeInfoWindow: function() {
                maps.info_window.close();
                // Must refresh to avoid info window slowdown when info windows are not closed with 'X'
                maps.refresh();
            },
            info_window: (new google.maps.InfoWindow()),
            geocoder: (new google.maps.Geocoder()),
            geocoder_status_codes: google.maps.GeocoderStatus,
            display_location_map_node: displayLocationMapNode,
            map_type: google.maps.MapTypeId.ROADMAP,
            refresh: function(){
                google.maps.event.trigger(maps.map, "resize");
                maps.map.setCenter(maps.map.getCenter());
            }
        });

        if (initialiseWith) {
            maps.show_map();
            maps.geodata = function (fn, args) {
                fn({all: [initialiseWith]});
            };
            maps.display_events({});
        } else {
            if (variant == "event_viewer") {
                var postcode = displayScope.find('input#origin-postcode').val();
                if (postcode) {
                    maps.display_events({ origin_postcode: postcode, limit: 20 });
                } else {
                    maps.get_and_display_events();
                }
            }
        }

        maps.bind_to_node(displayScope, true, true);
        displayScope.find('button[value="refresh"]').click(function(){
            displayScope.find('input#origin-postcode').val("");
            maps.get_and_display_events();
            return false;
        });

        if (navigator.geolocation) {
            getup.geo.user({map: maps, location_property: "user_location", locator: navigator.geolocation });
        }

        displayLocationMapNode.on('refresh-map', function(){
            maps.refresh();
        });

    };

    if (window.google === undefined) {
        var script = document.createElement("script");
        script.type = "text/javascript";
        script.src = "https://maps.google.com/maps/api/js?sensor=false&key="+apiKey+"&region=AU&libraries=geometry&callback=bootstrap_maps";
        document.body.appendChild(script);
    } else {
        bootstrap_maps();
    }

}
