function configureTestimonialModule(contentModuleId, trackingToken, appId, pageId) {
  $(document).on('fb-load', function() {
    FB.Event.subscribe('comment.create', window.commentCreateSubscribe = function(subscribeResponse){
      var commentsUrl = "https://graph.facebook.com/comments?order=reverse_chronological&filter=stream&ids=" + subscribeResponse.href;
      $.get(commentsUrl, function(commentsResponse) {
        var comments, i;
        if (commentsResponse.error){ return console.error(commentsResponse); }
        comments = commentsResponse[subscribeResponse.href].comments.data;
        for (i = 0; i < comments.length; i++) {
          if (comments[i].id === subscribeResponse.commentID){
            $.post('/testimonial/record_action', 
              {'facebook_id': comments[i].from.id, 
                'module_id': contentModuleId, 
                't': trackingToken,
                'app_id': appId,
                'page_id': pageId,
                'testimonial_text': comments[i].message
              });
            break;
          }
        }
      });
    });
  });

  (function(d, s, id) {
  var js, fjs = d.getElementsByTagName(s)[0];
  if (d.getElementById(id)){ return; }
  js = d.createElement(s); js.id = id;
  js.src = "//connect.facebook.net/en_GB/sdk.js#xfbml=1&version=v2.5&appId=1387640914791848";
  fjs.parentNode.insertBefore(js, fjs);
  }(document, 'script', 'facebook-jssdk'));
}
