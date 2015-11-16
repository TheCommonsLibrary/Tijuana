var Doorknock = {
    fetchStreets: function(suburb_name, streetsContainer, ajaxUrl) {
    $.ajax({
        url: ajaxUrl,
        data: {suburb_name: suburb_name},
        success: function(data) {
           streetsContainer.html('');
            if (data.length > 0) {
                streetsContainer.removeAttr("disabled");
                streetsContainer.append($("<option />").val('').text('--Choose your street--'));
                $.each(data, function() {
                    streetsContainer.append($("<option />").val(this.id).text(this.name));
                });
            } else {
                streetsContainer.append($("<option />").text('--No Streets Available--'));
                streetsContainer.attr("disabled", "disabled");
            }
        },
        error: function() {
            alert("An error occurred fetching available streets");
        }
    });
  },
  isStreetSelected: function(street_id) {
      return parseInt(street_id, 10) > 0;
  },
  fetchStreetsOnSuburbChange: function(doorknock, ajaxUrl) {
      doorknock.find('.suburb_name').change(function() {
          Doorknock.fetchStreets(doorknock.find('.suburb_name').val(), doorknock.find('.street_container'), ajaxUrl);
      });
  }
};
