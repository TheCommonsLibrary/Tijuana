describe("the getShortenedContent function in readmore", function() {
  it("should truncate content to be the same when length is longer than text", function () {
    var content = $("<div>First element<h1>Second element</h1><h2>Third Element</h2>Fourth Element</div>");
    var shortenedContent = getShortenedContent(content, 150);
    expect(shortenedContent[3].text()).toEqual("Fourth Element");
    expect(shortenedContent.length).toBe(4);
  });
  
  it("should truncate content to only give 2 divs with a contents greater than 20 characters", function () {
    var content = $("<div>First element<h1>Second element</h1><h2>Third Element</h2>Fourth Element</div>");
    var shortenedContent = getShortenedContent(content, 20);
    expect(shortenedContent[1].text()).toEqual("Second element");
    expect(shortenedContent.length).toBe(2);
  });

  it("should remove image tags as well as youtube, leaving only text", function() {
    var content = $("<div>First element<iframe></iframe><img src='' /><h1>Hello World</h1></div>");
    var shortenedContent = getShortenedContent(content, 150);
    expect(shortenedContent[1].prop('outerHTML')).toEqual("<h1>Hello World</h1>");
    expect(shortenedContent.length).toBe(2);
  });

  it('should not take out br tags within text', function() {
    var content = $("<div><h1>Hello World</h1><br><br>It is me</div>");
    var shortenedContent = getShortenedContent(content, 150);
    expect(shortenedContent.length).toBe(4);
    expect(shortenedContent[0].prop('outerHTML')).toEqual("<h1>Hello World</h1>");
    expect(shortenedContent[1].prop('outerHTML')).toEqual("<br>");
    expect(shortenedContent[2].prop('outerHTML')).toEqual("<br>");
    expect(shortenedContent[3].text()).toEqual("It is me");
  });

  it('should strip outer br tags', function() {
    var content = $("<div><br><h1>Hello World</h1><br><br>It is me<br><br></div>");
    var shortenedContent = getShortenedContent(content, 150);
    expect(shortenedContent.length).toBe(4);
    expect(shortenedContent[0].prop('outerHTML')).toEqual("<h1>Hello World</h1>");
    expect(shortenedContent[1].prop('outerHTML')).toEqual("<br>");
    expect(shortenedContent[2].prop('outerHTML')).toEqual("<br>");
    expect(shortenedContent[3].text()).toEqual("It is me");
  });
});