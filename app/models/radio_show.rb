class RadioShow < ActiveRecord::Base
  extend RemoveIdProtection

  belongs_to :radio_station

  acts_as_mappable :through => :radio_station

  validates :from_time, :presence => true
  validates :to_time, :presence => true
  validates :website, :format => { :with => URI::regexp(["http", "https"]), :allow_blank => true }
  validates :show_type, :inclusion => { :in => ["TALKBACK", "RING_REQUEST"] }

  def self.find_radio_shows(origin_lat, origin_long)
    maximum_radius = RadioStation.maximum(:broadcast_radius)
    all_shows = RadioShow.joins(:radio_station).within(maximum_radius, {:origin => [origin_lat, origin_long], :units => :kms}).order("radio_stations.name asc")
    show_you_can_reach = all_shows.select { |show| show.distance <= show.radio_station.broadcast_radius }

    shows = show_you_can_reach.partition { |show| show.on_air? }
    {:now => shows[0].sort_by { rand }, :not_now => shows[1]}
  end

  def on_air?
    time_now = Time.now.utc
    from_and_to_time = convert_time_to_timestamp
    (from_and_to_time[:from] <= time_now && from_and_to_time[:to] >= time_now)
  end

  def parse_time(column, time_string, state)
    write_attribute(column, Time.use_zone(time_zone(state)){Time.zone.parse(time_string).utc})
  end

  def from_time_localised
    from_time.in_time_zone(time_zone radio_station.state).strftime "%l:%M %P"
  end

  def to_time_localised
    to_time.in_time_zone(time_zone radio_station.state).strftime "%l:%M %P"
  end

  def convert_time_to_timestamp
    from_date, to_date = Date.today

    if from_time > to_time
      from_date = (from_date - 1.day).to_date
    end

    {:from => Time.parse("#{from_date} #{from_time.strftime "%H:%M:%S"}" + " UTC"), :to => Time.parse("#{to_date} #{to_time.strftime "%H:%M:%S"}" + " UTC")}
  end

  private :convert_time_to_timestamp

  def time_zone(state)
    time_zones = {
        "QLD" => "Australia/Brisbane",
        "NSW" => "Australia/Sydney",
        "VIC" => "Australia/Melbourne",
        "SA" => "Australia/Adelaide",
        "ACT" => "Australia/Melbourne",
        "TAS" => "Australia/Hobart",
        "NT" => "Australia/Darwin",
        "WA" => "Australia/Perth",
    }
    time_zones[state]
  end

  private :time_zone

end