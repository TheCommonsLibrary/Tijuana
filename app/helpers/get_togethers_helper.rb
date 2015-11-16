module GetTogethersHelper
  def search_radius_options_for_select(radius = 50)
    options_for_select([['5km radius', 5], ['15km radius', 15], ['25km radius', 25], ['50km radius', 50], ['150km radius', 150]], radius)
  end

  def map_bubble_template(get_together)
    escape_javascript %Q(
        <div id="event-info-box">
          <a href="{{path_with_token}}">
            <div class="event-info-details">
              <h1>{{name}}</h1>
              <div><strong>{{suburb}}</strong></div>
              <span class="info verbose">
                {{#distance}}<strong>Distance {{distance}}</strong>{{/distance}}
              </span>
            </div>
            {{#is_open}}
              <form method="link" action="{{path}}">
                <input type="hidden" name="t" value="{{token}}" />
                <input type="submit" class="events-button btn btn-primary" value="#{get_together.action_button_text}" />
              </form>
            {{/is_open}}
            {{#is_full}}
              <div class="event-info-full">#{get_together.event_full_message.html_safe}</div>
            {{/is_full}}
            {{#is_ended}}
              <div class="event-info-closed">#{get_together.event_closed_message.html_safe}</div>
            {{/is_ended}}
          </a>
        </div>
    )
  end

  def event_search_template(get_together)
    escape_javascript %Q(
      <li id="search-result-{{order}}">
        <img alt="Map marker" class="event-marker event-center" src="/images/map-markers/{{status}}/{{#order}}marker{{order}}{{/order}}{{^order}}blank{{/order}}.png" />
        <span class="event-name event-center">
          {{name}}
          <span class="event-tagline event-center"><br />{{street}}, {{suburb}} {{#distance}}({{distance}}){{/distance}}</span>
        </span>
        {{#is_open}}
          <form method="link" action="{{path}}">
            <input type="submit" class="event-attend btn btn-primary btn-med" value="#{get_together.action_button_text}" />
          </form>
        {{/is_open}}
        {{#is_full}}
          <div class="event-results-full">#{get_together.event_full_message}</div>
        {{/is_full}}
        {{#is_ended}}
          <div class="event-info-closed">This event is in the past</div>
        {{/is_ended}}
      </li>
    )
  end
end
