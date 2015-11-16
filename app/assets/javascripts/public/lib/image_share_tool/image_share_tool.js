var imageShareTool = function(appId, canvasId, captionSelector, downloadBtnSelector, fbBtnSelector, bgImgId, formSelector, pageName, pageDescription, pageCaption, loadingContainerSelector, nextPageUrl, disableUserDetails, captionX, captionY, fontSizePx, fontFamily, fontColour, uppercase, rightPadding) {
  var $caption = $(captionSelector);
  var fontStyle = fontSizePx + "px '" + fontFamily + "'";

  FB.init({
    appId      : appId,
    xfbml      : true,
    cookie     : true,  // enable cookies to allow the server to access 
    version    : 'v2.5'
  });

  //kick off setup on load to ensure the image has already loaded
  $(window).load(setupCanvas);

  function isBlank(str) {
    return (!str || /^\s*$/.test(str));
  }

  function validateCaption() {
    var blank = isBlank($caption.val());
    if (blank) {
      $('.caption-alert').remove();
      $caption.after('<div class="caption-alert alert-block alert-error">Please enter your text</div>');
    } else {
      $(".caption-alert").remove();
    }
    return !blank;
  }

  function preActionValidationPassed(e) {
    e.preventDefault();
    if (!disableUserDetails && !tijuana.lookupUser.isCompleted()) {
      tijuana.lookupUser.forceLookup(function() {});
      return false;
    }
    if (!validateCaption()) {
      return false;
    }
    return true;
  }

  function setupCanvas() {
    var canvas = document.getElementById(canvasId);
    var ctx = canvas.getContext('2d');
    var $downloadBtn = $(downloadBtnSelector);
    var $fbBtn = $(fbBtnSelector);
    var $loadingContainer = $(loadingContainerSelector);
    var $form = $(formSelector);
    var bgImg = document.getElementById(bgImgId);
    bgImg.setAttribute('crossOrigin', 'anonymous');
    var canvasWidth = bgImg.naturalWidth;
    var canvasHeight = bgImg.naturalHeight;

    //cloudinary
    $form.append($.cloudinary.unsigned_upload_tag("ohhjz7tz", { cloud_name: 'dj0qnpoau' }));
   
    hideLoadingImage();

    $fbBtn.click(uploadAndShare);

    canvas.width = canvasWidth;
    canvas.height = canvasHeight;
    drawImg();
    FontFaceOnload(fontFamily, {
      success: function() {
        drawImg(); //ensure the drawing happens after the font has loaded otherwise the text is not rendered
      }
    });
    
    $caption.on('input', drawImg);

    function hideLoadingImage() {
      $loadingContainer.hide();
    }

    function downloadCanvas(link, canvasId, filename) {
      canvas.toBlob(function(blob) {
        saveAs(blob, "download.png");
      });
    }

    $downloadBtn.click(function(e) {
      if (!preActionValidationPassed(e)) {
        return;
      }
      downloadCanvas(this, 'canvas', 'test.png');
      if (!disableUserDetails) {
        copyFormRewriteCaption().submit();
      } else {
        window.location.href = nextPageUrl;
      }
    });

    function drawImg() {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.drawImage(bgImg, 0, 0, canvasWidth, canvasHeight);
      
      ctx.font = fontStyle;
      ctx.strokeStyle = fontColour;
      ctx.fillStyle = fontColour;
      ctx.textBaseline = 'top';
      var lineHeight = 74;

      textLineBreaks(ctx, lineHeight);
    }

    function drawText(ctx, text, x, y, yOffset, textAlign) {
      if (text.length === 0) {
        return;
      }

      ctx.textAlign = textAlign;
      var xLine = x;
      if (textAlign === 'right') {
        xLine = x - (width);
      }

      var minXY=getTextTop(text);

      ctx.lineWidth = 1;
      ctx.strokeText(uppercase ? text.toUpperCase() : text, x-minXY.x,y-minXY.y);
      ctx.fillText(uppercase ? text.toUpperCase() : text, x-minXY.x,y-minXY.y);
    }
    
    //hack for firefox
    function getTextTop(text){
        // create temp working canvas
        var c=document.createElement('canvas');
        var w=canvas.width;
        var h=fontSizePx*2;
        c.width=w;
        c.height=h;
        var cctx=c.getContext('2d');
        // set font styles
        cctx.textBaseline='top';
        cctx.font=fontStyle;
        cctx.fillStyle='red';
        // draw the text
        cctx.fillText(text,0,0);
        // get pixel data
        var imgdata=cctx.getImageData(0,0,w,h);
        var d=imgdata.data;
        // scan pixel data for minX,minY
        var minX=10000000;
        var minY=minX;
        for(var y=0;y<h;y++){
        for(var x=0;x<w;x++){
            var n=(y*w+x)*4
            if(d[n+3]>0){
                if(y<minY){minY=y;}
                if(x<minX){minX=x;}
            }
        }}
        // return the leftmost & topmost pixel of the text
        return({x:minX,y:minY});
    }

    function textLineBreaks(ctx, lineHeight) {
      var text = $caption.val();
      if (isBlank(text)) {
        return;
      }
      var x = captionX;
      var y = captionY;
      var maxWidth = canvasWidth- rightPadding;
      var fromBottom = false;
      var pushMethod = (fromBottom)?'unshift':'push';
      lineHeight = (fromBottom)?-lineHeight:lineHeight;
      var lines = [];
      var line = '';
      var words = text.split(' ');

      for (var n = 0; n < words.length; n++) {
        var testLine = line + ' ' + words[n];
        var metrics = ctx.measureText(testLine);
        var testWidth = metrics.width;

        if (testWidth > maxWidth) {
          lines[pushMethod](line);
          line = words[n] + ' ';
        } else {
          line = testLine;
        }
      }
      lines[pushMethod](line);

      for (var k in lines) {
        drawText(ctx, lines[k], x, y + lineHeight * k, lineHeight, 'left');
      }
    }

    function enableFbPostButton() {
      $fbBtn.prop('disabled', false);
      $fbBtn.find(".text").text("Share on facebook");
    }

    function disableFbPostButton() {
      $fbBtn.prop('disabled', true);
      $fbBtn.find(".text").text("Posting...");
    }

    function copyFormRewriteCaption() {
      var $formCopy = $form.clone();
      var captionValue = $caption.val();
      $formCopy.find(".caption").val(captionValue);
      return $formCopy;
    }

    function submitFormAndRedirectToFb(imageUrl) {
      if (!disableUserDetails) {
        $.post( $form.attr('action'), copyFormRewriteCaption().serialize(), function() {
          var redirectUrl = 'https://www.facebook.com/dialog/feed?app_id=' + appId + '&caption=' + pageCaption + '&link=' + window.location + '&description=' + pageDescription + '&name=' + pageName + '&picture=' + imageUrl + '&redirect_uri=' + nextPageUrl;
          window.location = redirectUrl;
        } );
      } else {
        var redirectUrl = 'https://www.facebook.com/dialog/feed?app_id=' + appId + '&caption=' + pageCaption + '&link=' + window.location + '&description=' + pageDescription + '&name=' + pageName + '&picture=' + imageUrl + '&redirect_uri=' + nextPageUrl;
        window.location = redirectUrl;
      }
    }

    function uploadAndShare(e) {
      if (!preActionValidationPassed(e)) {
        return;
      }
      
      disableFbPostButton();
      $.cloudinary.config({ cloud_name: 'dj0qnpoau', api_key: '739278569963362'})

      var data = canvas.toDataURL('image/png');
      $('.cloudinary_fileupload').fileupload('option', 'formData').file = data;
      $('.cloudinary_fileupload').fileupload('add', { files: [ data ] });

      $('.cloudinary_fileupload').bind('cloudinarydone', function(e, data) {
        submitFormAndRedirectToFb(data.result.url);
      });
    }
  }
};
