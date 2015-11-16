var tijuana = tijuana || {};

// ripped out of jquery v1.7.2 because we can't rely on jquery being loaded at this point
tijuana.grep = function( elems, callback, inv ) {
	var ret = [], retVal;
	inv = !!inv;

	for ( var i = 0, length = elems.length; i < length; i++ ) {
		retVal = !!callback( elems[ i ], i );
		if ( inv !== retVal ) {
			ret.push( elems[ i ] );
		}
	}

	return ret;
};

tijuana.allowTrackJsError = function(payload) {
  var allowOnly = [
    [new RegExp("https:\/\/\.*getup\.org\.au", "i"), payload.file],
    [new RegExp("https:\/\/\.*australiansforaction\.org\.au", "i"), payload.file]
  ];
  
  var allowNone = [
    [new RegExp("addthis", "i"), payload.stack],
    [new RegExp("MSIE (5|6|7|8)", "i"), payload.environment.userAgent]
  ];
  
  var allowed = tijuana.grep(allowOnly, function(rule) { return rule[0].test(rule[1]); }).length > 0;
  var notAllowed = tijuana.grep(allowNone, function(rule) { return rule[0].test(rule[1]); }).length > 0;
  
  return allowed && !notAllowed;
};
