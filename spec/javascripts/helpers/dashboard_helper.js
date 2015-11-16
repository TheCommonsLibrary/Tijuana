function triggerKeyEventWithKey(event, element, keyCode) {
    var keyDownEvent = $.Event(event);
    keyDownEvent.which = keyCode;
    element.trigger(keyDownEvent);
}