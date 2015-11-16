module MpActionHelper
  def evaluate_fallback_action_message(mp_content_module, mp, senator)
    case mp_content_module
      when CallMPModule
        if mp_content_module.visit_target?
          visit_mp_fallback_template(mp_content_module, mp, senator)
        elsif mp_content_module.mail_target?
          mail_mp_fallback_template(mp_content_module, mp, senator)
        else
          call_mp_fallback_template(mp_content_module, mp, senator)
        end
      when EmailMPModule then "#{mp ? mp.full_name : "Your representative"} does not represent one of the target parties of this campaign, your email will go to Senator #{senator.full_name} instead."
    end
  end

  def evaluate_action_message(mp_content_module, parliamentarian)
    case mp_content_module
      when CallMPModule
        if mp_content_module.visit_target?
          visit_mp_module_action_message(mp_content_module, parliamentarian)
        elsif mp_content_module.mail_target?
          mail_mp_module_action_message(mp_content_module, parliamentarian)
        else
          call_mp_module_action_message(mp_content_module, parliamentarian)
        end
      when EmailMPModule
        "Your email will go to #{parliamentarian.is_a?(Senator) ? "Senator " : ""}#{parliamentarian.full_name}."
    end
  end

  def format_time_slice(from)
    friendly_day = from.to_date == Date.today ? "Today" : "%a"
    from.strftime("#{friendly_day} %d %b at %I:%M%P")
  end
  
  def format_call_reminder(time)
    friendly_day = time.to_date == Date.today ? "Today" : "%a"
    time.strftime("At %l:%M%P #{friendly_day} %d %b")
  end
  
  private

  def call_mp_fallback_template(mp_content_module, mp, senator)
    <<TEMPLATE
<div class="mp-evaluated-msg">
  #{mp ? mp.full_name : "Your representative"} does not represent one of the target parties<br>
  Please call your Senator<br>
  #{senator.full_name}<br>
  <span>#{get_phone(mp_content_module, senator)}</span>
</div>
TEMPLATE
  end

  def visit_mp_fallback_template(mp_content_module, mp, senator)
    <<TEMPLATE
<div class="mp-evaluated-msg">
  #{mp ? mp.full_name : "Your representative"} does not represent one of the target parties<br>
  Please instead visit the offices of your Senator<br>
  #{senator.full_name}<br>
  <span>#{get_phone(mp_content_module, senator)}</span><br>
  <span>#{get_address(mp_content_module, senator)}</span>
</div>
TEMPLATE
  end

  def mail_mp_fallback_template(mp_content_module, mp, senator)
    <<TEMPLATE
<div class="mp-evaluated-msg">
  #{mp ? mp.full_name : "Your representative"} does not represent one of the target parties<br>
  Please instead hand deliver to the offices of your Senator:<br>
  #{senator.full_name}
  <p>
  <span>#{get_address(mp_content_module, senator)}</span>
  </p>
  <p>Alternatively, post the letter to:</p>
  <p>
  <span>#{get_address(mp_content_module, senator, mail:true)}</span>
  </p>
</div>
TEMPLATE
  end

  def call_mp_module_action_message(mp_content_module, parliamentarian)
      phone_number = get_phone(mp_content_module, parliamentarian)
      <<TEMPLATE
<div class="mp-evaluated-msg #{'schedule_calls' if mp_content_module.schedule_calls?}">
  <hr/>
  Please call your #{parliamentarian.is_a?(Senator) ? "Senator" : "MP" }
  <br/>
  #{parliamentarian.full_name}
  <br/>
  <br/>
  <div class="call-time"></div>
  <div class="mp-phone-number">
    <span class="icon">
      <i class="icon-phone icon-large"></i>
    </span>
    <span class="text phone-number">
     #{phone_number}
    </span>
  </div>
  <br/>
</div>
TEMPLATE
  end

  def visit_mp_module_action_message(mp_content_module, parliamentarian)
      phone_number = get_phone(mp_content_module, parliamentarian)
      address = get_address(mp_content_module, parliamentarian)
      <<TEMPLATE
<div class="mp-evaluated-msg #{'schedule_calls' if mp_content_module.schedule_calls?}">
  <hr/>
  Office details for your #{parliamentarian.is_a?(Senator) ? "Senator" : "MP" }
  <br/>
  #{parliamentarian.full_name}
  <br/>
  <br/>
  <div class="call-time"></div>
  <div class="mp-phone-number">
    <span class="text phone-number">
     #{address}
    </span><br><br>
    <span class="icon">
      <i class="icon-phone icon-large"></i>
    </span>
    <span class="text phone-number">
     #{phone_number}
    </span>
  </div>
  <br/>
</div>
TEMPLATE
  end

  def mail_mp_module_action_message(mp_content_module, parliamentarian)
      mail_address = get_address(mp_content_module, parliamentarian, mail: true)
      office_address = get_address(mp_content_module, parliamentarian)
      <<TEMPLATE
<div class="mp-evaluated-msg #{'schedule_calls' if mp_content_module.schedule_calls?}">
  <hr/>
  Your #{parliamentarian.is_a?(Senator) ? "Senator" : "MP" } is #{parliamentarian.full_name}
  <br/>
  <div class="call-time"></div>
  <div class="mp-details">
  <p>
    Either hand deliver to their office:
  </p>
  <p>
    <span class="text">
     #{office_address}
    </span>
  </p>
  <p>
    Alternatively, send to their postal address:
  </p>
  <p>
    <span class="text">
     #{mail_address}
    </span>
  </p>
  </div>
  <br/>
</div>
TEMPLATE
  end

  def get_phone(mp_content_module, parliamentarian)
    parliamentarian.send("#{mp_content_module.target_phone}_phone")
  end

  def get_address(mp_content_module, parliamentarian, mail: false)
    prefix = mail ? 'mailing' : mp_content_module.target_phone
    [
      parliamentarian.send("#{prefix}_address").to_s.split(',').join(',<br>'),
      [
        parliamentarian.send("#{prefix}_suburb"),
        parliamentarian.send("#{prefix}_state"),
        parliamentarian.send("#{prefix}_postcode")
      ].join(' ')
    ].join('<br>')
  end
end

