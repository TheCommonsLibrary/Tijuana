var tijuana = tijuana || {};

tijuana.isTestEnvironment = function(condition, message) {
  return $('body').data('environment') === 'test' || $('title').text() === 'Jasmine Specs';
};