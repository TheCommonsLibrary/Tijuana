var initEmailMpModule = (function(){
    function toggleTargetSenate(upperHousePresent) {

        if (upperHousePresent === true) {
            $("#target-selection").show();
        } else {
            $("#target-selection select").val('MPs');
            $("#target-selection").hide();
        }
    }

    function init(options){

        toggleTargetSenate(options.upperHousePresent);
        $("#jurisdiction-select").change(function(){
            $.ajax({
                url: options.url,
                data: options.data + "&jurisdiction=" + $(this).val(),
                success: function(data){
                    $(options.resultsContainer).html(data.html);
                    toggleTargetSenate(data.target_senate);
                },
                dataType: "json"
            });


        });
    }

    return init;
})();



