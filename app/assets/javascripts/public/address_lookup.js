$.fn.checkAddress = function (options) {
  var defaults = {
    endPoint: '',
    addressMinLength: 2,
    delay: 200,
    timeout: 10000,
    searchResultLimit: 20
  };
  options = $.extend(defaults, options);
  var $txtInputAddressLookup = this.find('#postal_address_address_search');
  var $hiddenInputSearchOutcome = this.find('#postal_address_search_outcome');
  var subPremiseResultId = null;

  this.find('a[data-toggle="tab"]').on('shown', function (event) {
    if (event.target.hash == '#manual-address') {
      $hiddenInputSearchOutcome.val('manual');
      $txtInputAddressLookup.val('');
    }
    else {
      $hiddenInputSearchOutcome.val('');
    }
  });

  $('a.cancel-search').click(function (e) {
    e.preventDefault();
    $('.address-tab-manual').first().tab('show');
  });
  var $msgSearchFailure = $('.search-failure-message');
  var $msgManualEntry = $('.manual-address-message');
  var tabManual = 'a[href="#manual-address"]';
  var tabSearch = 'a[href="#address-search"]';
  var visibleTab = $('#postal_address_search_outcome').val() == 'manual' ? tabManual : tabSearch;
  $(visibleTab).tab('show');
  var requests = [];
  var failed = 0;
  $txtInputAddressLookup.autocomplete({
    source: function (request, response) {
      var xhr = $.ajax({
        url: options.endPoint,
        data: {
          initial_address_query: ($txtInputAddressLookup.length > 0 ? $txtInputAddressLookup.val() : ''),
          drill_down_search_result_id: subPremiseResultId
        },
        dataType: 'json',
        success: function (data) {
          subPremiseResultId = null;
          $hiddenInputSearchOutcome.val('');
          failed = 0;
          $msgSearchFailure.addClass('hide');
          response($.map(data.results.slice(0, options.searchResultLimit), function (item) {
            return {
              value: item.formatted_address,
              label: item.formatted_address,
              contains_subpremises: item.contains_subpremises,
              search_result_id: item.search_result_id,
              data: item
            };
          }));
        },
        error: function (xhr, textStatus, errorThrown) {
          failed++;
          if(failed > 2) {
            for(var i=0; i<requests.length; i++) {
              requests[i].abort();
            }
            $(tabManual).tab('show');
            $msgManualEntry.addClass('hide');
            $msgSearchFailure.removeClass('hide');
          }
        },
        timeout: options.timeout
      });
      requests.push(xhr);
    },
    delay: options.delay,
    minLength: options.addressMinLength,
    select: function (event, ui) {
      if (event.keyCode == 9) {
        return false;
      }
      if (ui.item.contains_subpremises) {
        subPremiseResultId = ui.item.search_result_id;
        return false;
      }
      else {
        $($hiddenInputSearchOutcome).val(ui.item.search_result_id);
      }
    },
    close: function () {
      if (subPremiseResultId !== null) {
        $(this).autocomplete('search');
      }
    },
    create: function (event, ui) {
      $('.ui-autocomplete').wrap('<span class="totalcheck"></span>');
      $txtInputAddressLookup.after($('.totalcheck'));
      $('.ui-menu').width('98%');
    },
    messages: {
      noResults: '',
      results: function () {
      }
    }
  }).data('autocomplete')._renderItem = function (ul, item) {
    var partial = '<a><table width="100%"><tr><td style="max-width:99%;">';
    partial += item.label + '</td><td style="max-width:1%;" valign="middle">';
    if (item.contains_subpremises) {
      partial += '<i class="tc-icon-subpremise"></i>';
    }
    partial += '</td></tr></table></a>';
    return $('<li>').data("item.autocomplete", item).append(partial).appendTo(ul);
  };
  return this;
};