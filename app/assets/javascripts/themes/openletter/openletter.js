//= require ./webticker

function position_action() {
    windowTop = $(window).scrollTop();
    mainOffset = $('#main').offset().top;
    windowHeight = $(window).height();
    headerHeight = $('#main').offset().top;
    mainHeight = $('#main').outerHeight();
    actionHeight = $('#action').outerHeight(); //8 for border size


    if (mainOffset > windowHeight - actionHeight && windowTop < windowHeight - mainOffset) {
        //$('#action').removeClass().addClass('action-top-scroll');
        $('#action').removeClass().addClass('action-bottom-fixed');
    } else if (windowTop < (headerHeight + mainHeight) - windowHeight) {
        $('header.primary h1').removeClass();
        $('#action').removeClass().addClass('action-bottom-fixed');
        $('.action-form').attr('class', 'action-form action-form-bottom-fixed');
        $('.action-count .caption').slideUp();
    } else if (windowTop > (headerHeight + mainHeight) - actionHeight) {
        $('header.primary h1').removeClass();
        $('#action').removeClass().addClass('action-top-fixed');
        $('.action-form').attr('class', 'action-form action-form-top-fixed');
        $('.action-count .caption').slideDown();
    } else if (windowTop < (headerHeight + mainHeight) - actionHeight) {
        $('header.primary h1').removeClass();
        $('#action').removeClass().addClass('action-bottom-scroll');
        $('.action-form').attr('class', 'action-form action-form-bottom-scroll');
        $('.action-count .caption').slideUp();
    }

    // if (windowTop <= 0)
    //     $(".ambassadors-wrap").css("overflow", "scroll");
    // else
    //     $(".ambassadors-wrap").css("overflow", "hidden");
    $(".ambassadors-wrap").css("overflow", "hidden");

    if (windowTop > actionHeight / 5) {
        $('#action').addClass('action-scrolling');
    }
}



// Image Panning for the Header

function imagePan() {

    var self = this,
        size = $('#ambassadors .ambassador:first').height(),
        timePerRow = 10000,
        i = 1;

    $('#ambassadors .ambassador').each( function() {
        $('#ambassadors').append($(this).clone());
    });

    this.move = function(iteration) {

        var top = size * iteration;

        $('#ambassadors .ambassador').each( function(index) {

            $(this).css({
                'height': size + 'px'
            });

        });

        $('#ambassadors').css({
            'transform': 'translate3d(0, -' + top + 'px, 0)',
            'transition': 'all ' + timePerRow + 'ms linear' 
        });

    };

    this.loop = function(iteration) {

        var rowCount = Math.round($(window).width() / size),
            rowStart = iteration * rowCount,
            rowEnd = rowStart + rowCount,
            $row = $('#ambassadors .ambassador').slice(rowStart, rowEnd);

        $row.each( function() {
            var top = size * iteration;
            $('#ambassadors').append($(this).clone());
        });

        var delay = setTimeout( function() {
            $row.each( function() {
                $(this).css('visibility','hidden');
            });
        }, timePerRow);

    };

    self.move(i);
    var update = setInterval( function() {

        i++;
        self.loop(i - 1);
        self.move(i);

    }, timePerRow);

    $(window).on('resize', function() {

        size = $('#ambassadors .ambassador:first img').height();
        $('#ambassadors .ambassador').each( function(index) {

            $(this).css({
                'height': size + 'px'
            });

        });

    });


}
$(window).load( function() {

    imagePan();

});

jQuery(function($) {

    //(re)move old dom (need to happen in ruby templates)
    $("footer section.graphics").remove();
    $("footer section.endorsement").remove();
    $("footer section.timeline").remove();

    //move content-modules outside of #main
    //partners
    $("#partners").removeClass("hidden").prependTo("section.notes .container");
    //html headers
    $("header.primary").each(function() {
        $section = $("<div/>", {
            'class': "ambassadors-wrap"
        });
        $(this).prepend($section);
        $section.html("<div id='ambassadors'></div>");
        $(".content-module #ambassadors img, .content-module #australians img").each(function(n) {
            wrap = "<div class='ambassador'>";
            wrap += "<img src='" + $(this).attr("src") + "'>";
            wrap += "<div class='overlay'><span class='ambassador-title'>" + $(this).attr("alt") + "</span><span class='ambassador-role'>" + $(this).attr("title") + "</span></div>";
            wrap += "</div>";
            $wrap = $(wrap);
            $wrap.prependTo($(".ambassadors-wrap #ambassadors"));
        });
    });

    $("#closure").each(function() {
        $section = $("<section/>", {
            'class': "timeline"
        });
        $("footer").prepend($section);
        $section.html("<img src='/assets/themes/openletter/timeline.png' width='100%'><div class='container'></div>");
        $(this).removeClass("hidden").appendTo("section.timeline .container");
    });
    $("#slides").each(function() {
        var $slides = $("<section/>", {
            'class': "endorsement"
        });
        $("footer").prepend($slides);
        $("img", this).each(function() {
            slide = "<div class='slide'>";
            slide += "<img src='" + $(this).attr("src") + "'>";
            slide += "<div class='container'>";
            slide += "<blockquote>\"" + $(this).attr("title") + "\"</blockquote>";
            slide += "<div class='profile'>";
            slide += "<div class='name'>" + $(this).attr("alt") + "</div>";
            slide += "</div>";
            slide += "</div>";

            $slide = $(slide);
            $slide.appendTo($slides);
        });
    });



    //remove "signatures" from the petition progress (core to getup module)
    $("article #action h3").text($("article #action h3").text().replace('signatures', ''));


    //set the header height based upon window height - action height (and then listen to events)
    if($(".petitionmodule #action").length > 0){
        $("header.primary").height($(window).height() - $(".petitionmodule #action").height());
        $(window).resize(function() {
            $("header.primary").height($(window).height() - $(".petitionmodule #action").height());
        });
        $(window).load(function() {
            $("header.primary").height($(window).height() - $(".petitionmodule #action").height());
        });
    }else{
        $("header.primary").height($(window).height() - $(window).height()/3);
    }
    
    //position
    if($("#main .progress").length === 0) {
        $("#main .well").append('<div class="progress"><div class="bar" style="width: 100%;"></div></div>');
    }

    var $videoSection = $('#video-section');
    if (window.location.href.indexOf("video") > -1 && $videoSection.length){
      // scroll to top of video section
      $('html, body').animate({
          scrollTop: $videoSection.offset().top - 10
      }, 2000);
    }else{
      // set start to bottom of squares
      $('header').scrollTop($('header')[0].scrollHeight);
    }

    // set position of action bar
    position_action();

    $(window).scroll(function() {
        position_action();
    });


    // recalculate if window is resized
    $(window).resize(function() {
        position_action();
        //squarify(square);
    });

    // form toggle
    $('#action form').hide().before("<button class='email'>Or sign with Email</button>");
    $('#action button.email').click(function(e) {
        e.preventDefault();
        $('#action form').slideToggle('fast');
    });

    // form validate
    $.getScript('//cdnjs.cloudflare.com/ajax/libs/jquery-validate/1.11.1/jquery.validate.min.js', function() {

        $('#action-form').validate();

    });

    $("#partners").webTicker({
      duplicate:true
    });
});


try { Typekit.load(); } catch (e) {}
