if (window.name && window.name.match(/\.css$/)) {
  $('head').append('<link href="'+window.name+'" media="screen" rel="stylesheet" type="text/css" />');
}
if (window.postMessage && parent){
  parent.postMessage(window.location.href, '*');
}

$(function(){
 $('article .container').css('visibility', 'visible');
 if ('parentIFrame' in window) {
   parentIFrame.size();
 }
});
