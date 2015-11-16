$(function() {
  $('.accordion-module').on('show', function(obj) {
    //hide inner instead of body because hiding body messes with collapse functionality
    $(obj.target).find('.accordion-body .accordion-inner').show();
  });
  $('.accordion-module').on('hide', function(obj) {
    $(obj.target).find('.accordion-body .accordion-inner').hide();
  });
});
