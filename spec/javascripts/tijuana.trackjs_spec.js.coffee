describe "tijuana.trackjs", ->
  buildPayload = (payload) ->
    jQuery.extend { file: 'https://www.getup.org.au', environment: { userAgent: "webkit" } }, payload
  
  it "should only track errors from getup urls", ->
    expect(tijuana.allowTrackJsError(buildPayload file: 'https://www.getup.org.au/donate')).toBe true
    expect(tijuana.allowTrackJsError(buildPayload file: 'https://www.australiansforaction.org.au')).toBe true
    expect(tijuana.allowTrackJsError(buildPayload file: 'https://s7.addthis.com/js/300/addthis_widget.js')).toBe false
  
  it "should not track errors where addthis is mentioned in the stacktrace", ->
    expect(tijuana.allowTrackJsError(buildPayload stack: 'https://s7.addthis.com/js/300/addthis_widget.js')).toBe false
    expect(tijuana.allowTrackJsError(buildPayload stack: 'ga.com/hello')).toBe true

  it "should not track IE 8.0, 7.0, 6.0 javascript errors", ->
    expect(tijuana.allowTrackJsError(buildPayload environment: { userAgent: 'MSIE 8.0' })).toBe false
    expect(tijuana.allowTrackJsError(buildPayload environment: { userAgent: 'webkit' })).toBe true
