$(function() {

  $.fn.qtip.defaults = $.extend(true, {}, $.fn.qtip.defaults, {
    position:{
      my: 'top center',
      at: 'bottom center',
      effect: false
    },
    style: {
      tip: {
        width: 25,
        height: 15
      },
      classes: 'customised-tooltip'
    }
  });
  // Select all elements that are to share the same tooltip
  var elems = $(".tooltip");

  // Create the tooltip on a dummy div since we're sharing it between targets
  elems.qtip(
  {
     content: ' ', // Can use any content here
     position: {
        target: 'event' // Use the triggering element as the positioning target
     },
     show: {
        target: elems
     },
     hide: {
        target: elems
     },
     events: {
        show: function(event, api) {
           // Update the content of the tooltip on each show
           var target = $(event.originalEvent.currentTarget);
           api.set('content.text', $("#"+target.attr('data-tip')).html());
        }
     }
   });
  
});