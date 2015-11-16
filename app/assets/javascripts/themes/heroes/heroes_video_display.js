var showLightBoxOnPageLoad = function() {
    var location = document.location.href;
    var anchor = location.substr(location.indexOf("#") + 1);
    $(".row").find("i[data-name='" + anchor + "']").click();
};

var displayVideoLightBox = function(videoUrl) {
    var videoModalBody = $('#videoModal').find('.modal-body')[0];
    var newVideo = document.createElement("iframe");

    newVideo.setAttribute('src', videoUrl);
    newVideo.setAttribute('frameborder', '0');
    videoModalBody.appendChild(newVideo);
};

$(function() {
    showLightBoxOnPageLoad();
});

$('.open-videoModal').click(function () {
    var videoUrl = $(this).data('id');
    displayVideoLightBox(videoUrl);
});

$('#videoModal').on('hidden.bs.modal', function (e) {
    var videoModalBody = $('#videoModal').find('.modal-body')[0];

    while (videoModalBody.firstChild) {
        videoModalBody.removeChild(videoModalBody.firstChild);
    }
});