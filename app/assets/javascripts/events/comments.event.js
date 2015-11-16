$(function(){
  $.each($('.event-comments form'), function(key, value){
    $(value).validate();
  });


  $('a.reply').click(function(event){
    var firstForm = $(this).parent().parent().parent().find('div.reply-to')[0];
    $(firstForm).show();
    event.preventDefault();
  });

  $('.cancel-reply').click(function(event){
    $(this).parent().parent().parent().hide();
    event.preventDefault();
  });
});
