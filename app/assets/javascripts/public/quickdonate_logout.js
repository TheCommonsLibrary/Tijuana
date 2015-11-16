var tijuana = tijuana || {};

tijuana.logoutQuickDonate = function() {
  // logout of quickdonate in the background. The response will clear cookie
  $.post('/users/logout_quickdonate');
};
