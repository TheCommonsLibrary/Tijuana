var toggle_edit_custom_fields = function() {
  $('.custom_fields_edit a').click(function(){
    $(this).nextAll('.custom_fields_container').toggle();
    return false;
  });
};
