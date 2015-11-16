function activityStream(options) {
  var delayBetweenRequests = 15000;
  var streamUrl = options.streamUrl;
  var itemCount = options.itemCount || 3;
  var delayBetweenItems = options.delayBetweenItems || 4000;
  var effect = options.effect || "blind";

  var list = $(options.listSelector);
  var preloaded = false;
  var toRender = [];
  var alreadyUsedIds = [];

  function addToList(activity) {
    var date, activityTimestamp, activityItem;

    if (!activity) { return; }

    activityItem = $("<div class='action'><div class='text'>" + activity.html + "</div></div>");
    list.prepend(activityItem);

    date = new Date(activity.timestamp);
    activityTimestamp = $("<div class='time'>" + distanceOfTimeInWordsToNow(date) + "</div>");
    activityTimestamp.data("actualDate", date);

    activityItem.hide();
    activityItem.append(activityTimestamp);
    activityItem.show(effect);

  }

  function preloadListAfterPageLoad() {
    for (var i = 0; i < itemCount; i++) {
      addToList(toRender.pop());
    }
    preloaded = true;
    setTimeout(renderFirstItemInActivityQueue, delayBetweenItems);
  }

  function removeLastItem() {
    if (list.find(".action").length <= itemCount) { return; }

    var lastItem = list.find(".action:last");
    lastItem.hide(effect, function() {
      lastItem.remove();
    });
  }

  function updateTimestamps() {
    list.find(".time").each(function(i, el) {
      var timestamp = $(el);
      var date = timestamp.data("actualDate");
      timestamp.text(distanceOfTimeInWordsToNow(date));
    });
  }

  function waitForAWhile() {
    setTimeout(getActivity, delayBetweenRequests);
  }

  function renderFirstItemInActivityQueue() {
    updateTimestamps();
    addToList(toRender.pop());
    removeLastItem();

    if (toRender.length === 0) {
      getActivity();
    } else {
      setTimeout(renderFirstItemInActivityQueue, delayBetweenItems);
    }
  }

  function queueActivity(data, status, xhr) {
    $.each(data, function(i, activity) {
      if($.inArray(activity.id, alreadyUsedIds) === -1) {
        alreadyUsedIds.push(activity.id);
        toRender.push(activity);
      }
    });
    if (preloaded) {
      if (toRender.length === 0) {
        updateTimestamps();
        waitForAWhile();
      } else {
        renderFirstItemInActivityQueue();
      }
    } else {
      preloadListAfterPageLoad();
    }
  }

  function getActivity() {
    $.getJSON(streamUrl, queueActivity);
  }
  getActivity();
}
