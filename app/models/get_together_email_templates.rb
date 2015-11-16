module GetTogetherEmailTemplates
  THANK_YOU_FOR_HOSTING = <<TEMPLATE
Dear {NAME|Friend},
Thank you for registering your event {EVENT_NAME}. Your event has its own unique webpage, at {EVENT_LINK}. Please use this link to make any changes to your event or view the event information.

Please find the details for your event below:

  EVENT NAME:    {EVENT_NAME}
  DATE AND TIME: {EVENT_DATE} - {EVENT_TIME}
  EVENT ADDRESS: {EVENT_ADDRESS}
  YOUR NOTES:    {EVENT_HOST_NOTES}

Here's something you can do right now:
<strong>Invite your friends and family to join you</strong>. This is the chance to mobilise a local action group to address the issues that are most important to your community. The more people who get involved, the greater the power you'll have. <b> Forward them this email and ask them to RSVP using the link above.</b>

We want to make sure that <strong>expectations are really clear</strong>, so here are some top-line points to guide you:
<li>This is your chance to see if there are other GetUp election volunteers in your area who want to join you in taking action locally - it's a one-off opportunity, and we won't be able to offer this again </li>
<li>Unfortunately <strong>we don't have resources</strong> to support these GetTogethers and the ideas that arise from these meetings - this is about local people working together to take <strong> independent action</strong> as local citizens</li>
<li>If you decide to take action, <strong>it's not "as GetUp"</strong> - this is about your issues, your community and the things you want to get done, so own it & enjoy it!</li>
<li>Your GetTogether will be open online until {EVENT_DATE}, for other GeUp members to attend!</li>


And finally, a few <strong>Frequently Asked Questions</strong>:
<li><strong>What if I register an event and no one shows up?</strong>
GetUp volunteers worked very hard and were very involved in the election campaign but people's time commitments area always changing so if you register a GetTogether and you don't get many RSVPs don't worry - it's not personal. </li>
<li><strong>Can we ask GetUp to support our actions or groups?</strong>
The local campaigns you and your group want to action will be an independent movement. So your events will no doubt be fantastic for your community, but unfortunately GetUp has very limited resources and will not have the capacity to follow up or support your events from this point.</li>
<li><strong>How do I get in touch with other hosts and GetTogether's in my region?</strong>
If you are hosting an event and see another event spring up nearby, RSVP to their event so you can get in touch and combine your groups if you want to.</li>

Good luck with your local campaigning!
From The GetUp! Team

TEMPLATE

  THANK_YOU_FOR_ATTENDING=<<TEMPLATE
Dear {NAME|Friend},

Thank you for RSVPing to {EVENT_NAME}. Your event has its own unique webpage, at {EVENT_LINK}. Follow that link to contact any other members who might be able to join you and also to see the details of your event.

Please find the details for your event below:

  EVENT NAME:    {EVENT_NAME}
  DATE AND TIME: {EVENT_DATE} - {EVENT_TIME}
  EVENT ADDRESS: {EVENT_ADDRESS}
  HOST NOTES:    {EVENT_HOST_NOTES}

Here's something you can do right now:
<strong>Invite your friends and family to join you</strong>. This is the chance to mobilise a local action group to address the issues that are most important to your community. The more people who get involved, the greater the power you'll have. <b> Forward them this email and ask them to RSVP using the link above.</b>

We want to make sure that <strong>expectations are really clear</strong>, so here are some top-line points to guide you:
<li>This is your chance to see if there are other GetUp election volunteers in your area who want to join you in taking action locally - it's a one-off opportunity, and we won't be able to offer this again </li>
<li>Unfortunately <strong>we don't have resources</strong> to support these GetTogethers and the ideas that arise from these meetings - this is about local people working together to take <strong> independent action</strong> as local citizens</li>
<li>If you decide to take action, <strong>it's not "as GetUp"</strong> - this is about your issues, your community and the things you want to get done, so own it & enjoy it!</li>
<li>Your GetTogether will be open online until {EVENT_DATE}, for other GeUp members to attend!</li>

Good luck with your local campaigning!<br>
From The GetUp! Team

TEMPLATE

  SOMEONE_IS_ATTENDING =<<TEMPLATE
Dear {NAME|Friend},<br><br>

A GetUp! member has just RSVPd to your event {EVENT_NAME}.<br>
You now have {EVENT_NUMBER_ATTENDEES} attendees and the maximum capacity of your event is {EVENT_CAPACITY}.<br><br>

You may edit your event by going to its own url at {EVENT_LINK}<br><br>

Good luck with your local campaigning!<br>
From The GetUp! Team

TEMPLATE

  SOMEONE_CANCELED_THEIR_ATTENDANCE =<<TEMPLATE
Dear {NAME|Friend},<br><br>

A GetUp! member has just Canceled their attendance.<br><br>

Reason: {REASON|Not given.}

You may edit your event by going to its own url at {EVENT_LINK}<br><br>

Good luck with your local campaigning!<br>
From The GetUp! Team

TEMPLATE

    ATTENDANCE_CANCELED_CONFIRMATION =<<TEMPLATE
Dear {NAME|Friend},<br><br>

Your attendance to the event {EVENT_NAME} event has been canceled.<br><br>

Sincerely,
From The GetUp! Team

TEMPLATE
end
