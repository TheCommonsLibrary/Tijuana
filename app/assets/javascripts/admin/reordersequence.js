function reorderSequence(reorderUrl, listSelector, toFlash) {
  function sequencesReordered(xhr) {
    $(toFlash).effect('highlight');
  }
  
  function reorderSequences() {
    $.ajax({
      url: reorderUrl,
      type: 'put',
      data: $(listSelector).sortable('serialize'),
      complete: sequencesReordered
    });
  }
  
  function unlockSorting() {
    var unlock = $(this);
    unlock.fadeOut();
    $('#' + unlock.attr('unlock')).find('.handle').fadeIn();
  }
  
  $(listSelector).sortable({
    axis: 'y',
    dropOnEmpty: false,
    handle: '.handle',
    cursor: 'crosshair',
    items: 'li',
    opacity: 0.4,
    scroll: true,
    update: reorderSequences
  }); 
  
  var unlock = $('.unlock-sorting');
  if (unlock.size() > 0) {
    $('.handle').hide(); 
    unlock.click(unlockSorting);
  }
}