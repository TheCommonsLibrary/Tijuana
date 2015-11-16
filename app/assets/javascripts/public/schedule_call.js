function scheduleCall(callMpForm) {
  function showTargetDetails() {
    callMpForm.find('.mp-evaluated-msg.schedule_calls').toggle($(this).val() !== "");
    callMpForm.find('.mp-evaluated-msg.schedule_calls .call-time').text($(this).find('option:selected').data('call-reminder'));
  }

  $(document).on('change', '#mp_start_time', showTargetDetails);
}