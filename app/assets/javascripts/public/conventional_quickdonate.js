var tijuana = tijuana || {};

tijuana.enableConventionalQuickDonateLogout = function(conventionalForm) {
  function assertElements() {
    if (conventionalForm.find('#credit').length !== 1) { throw 'Expected to have donation form using credit card'; }
    if (conventionalForm.find('.reset-quick-donate').length !== 1) { throw 'Expected to have link to log out of quick donate'; }
    if (conventionalForm.find('.invitation').length !== 1) { throw 'Expected to have invitation to enrol in to quick donate'; }
    if (conventionalForm.find('.quick-donate-form').length !== 1) { throw 'Expected to have quick donate form'; }
  }

  function hookUpNotYouToLogoutQuickDonate() {
    conventionalForm.find(".reset-quick-donate").click( function(e) {
      tijuana.logoutQuickDonate();
      conventionalForm.find(".invitation").css("display", "block");
      conventionalForm.find(".quick-donate-form").css("display", "none");
      e.preventDefault();
    });
  }
  
  if (tijuana.isTestEnvironment()) {
    assertElements();
  }
  hookUpNotYouToLogoutQuickDonate();
};
