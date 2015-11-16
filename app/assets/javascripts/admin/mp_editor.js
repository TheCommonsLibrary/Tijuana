function mpEditor(gritterSuccessImagePath, gritterErrorImagePath) {

    function gritter(cellAndRow, success, errorMsg) {
        var cellIndex = cellAndRow[0].cellIndex;
        var rowIndex = cellAndRow[1].rowIndex;
        var cellHeader = $($('table th')[cellIndex]).text();
        var mpLast = $($('table tr:eq(' + rowIndex + ') td span:eq(0)')[0]).text();
        var mpFirst = $($('table tr:eq(' + rowIndex + ') td span:eq(1)')[0]).text();
        if(success) {
          $.gritter.add({image: gritterSuccessImagePath, sticky: false, title: 'Success', text: 'Updated "' + cellHeader + '" for "' + mpFirst + ' ' + mpLast + '"'});
        } else {
          $.gritter.add({image: gritterErrorImagePath, sticky: false, title: 'Error', text: errorMsg});
        }
    }

    $('.best_in_place').bind("ajax:success", function () {
        var cellAndRow = $(this).parents('td,tr');
        gritter(cellAndRow, true, null);
    }).bind("ajax:error", function(event, data) {
        var cellAndRow = $(this).parents('td,tr');
        if (data.responseText === "") {
          alert("No response from server");
        } else {
          gritter(cellAndRow, false,JSON.parse(data.responseText)[0]);
        }
    });

    jQuery(".best_in_place").best_in_place();
}
