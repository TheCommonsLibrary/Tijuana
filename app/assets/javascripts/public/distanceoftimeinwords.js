function distanceOfTimeInWords(fromTime, toTime, includeTime) {
  var delta = parseInt((toTime.getTime() - fromTime.getTime()) / 1000, 10);
  if (delta < 60) {
      return delta + ' sec ago';
  } else if (delta < 120) {
      return '1 min ago';
  } else if (delta < (45*60)) {
      return (parseInt(delta / 60, 10)).toString() + ' min ago';
  } else if (delta < (120*60)) {
      return '1 hour ago';
  } else if (delta < (24*60*60)) {
      return (parseInt(delta / 3600, 10)).toString() + ' hours ago';
  } else if (delta < (48*60*60)) {
      return '1 day ago';
  } else {
    var days = (parseInt(delta / 86400, 10)).toString();
    return days + " days ago";
  }
}

function distanceOfTimeInWordsToNow(fromTime) {
  return distanceOfTimeInWords(fromTime, new Date());
}
