module Admin::PushesHelper

  def link_to_create_or_update(blast)
    if blast.list
      link_to "Edit List", admin_list_cutter_edit_path(:list_id => blast.list)
    else
      link_to "Cut a list", admin_list_cutter_new_path(:blast_id => blast)
    end
  end
  
  def member_count(blast)
    count = case blast.list && blast.list.latest_user_count && blast.list.latest_user_count
      when nil
        ""
      else
        "(#{pluralize(blast.list.latest_user_count, "member")})"
    end
  end

  def notice(class_name, message)
    "<div class='#{class_name}'><p>#{message}</p></div>"
  end

  def in_progress_msg(blast)
    if blast.push.cancelling_multiblast?
      <<MSG
<div class="email-send">
  <strong class="in-progress">Multi blast interrrupted, please wait... <a class="reload-page" href="">refresh</a></strong>
</div>
MSG
    else
    cancel_path = blast.push.sending_multiblast? ?
        Rails.application.routes.url_helpers.cancel_multiblast_admin_push_path(blast.push) :
        Rails.application.routes.url_helpers.cancel_admin_blast_path(blast)
    <<MSG
<div class="email-send">
  <strong class="in-progress">
    <div class="countdown">#{blast.remaining_time_for_existing_jobs}</div>
    <a class="reload-page" href="">refresh</a> | #{link_to "undo", cancel_path, :method => 'POST', :class => 'js-undo-link'}
  </strong>
</div>
MSG
    end
  end

  def can_send(blast)
    if blast.list.nil?
      notice("email-send", "Blast requires a list in order to send.")
    elsif blast.proofed_emails.size == 0
      notice("email-send", "There are no proofed emails ready to send")
    elsif blast.proofed_emails.size > 0
      if !blast.has_pending_jobs? && blast.push.has_pending_jobs?
        if (blast.push.sending_multiblast? && blast.push.multiblast_contains_blast?(blast.id))
          return  notice("completed", "Multi blast has completed sending of this blast.")
        else
          return  notice("blocked", "This blast can't be sent right now - check that the other blasts have finished first.")
        end
      elsif blast.has_pending_jobs?
        return in_progress_msg(blast)
      elsif current_push = Push.currently_delivering
        notice("email-send", "Push <a href=\"/admin/pushes/#{current_push.id}\" target=\"_BLANK\"><em>#{current_push.name}</em></a> is currently delivering. Reload the page when it has completed.")
      end
    end
  end
end
