module ElectorateBooths
  extend ActiveSupport::Concern
  def target_electorate
    most_populous_electorate_for_postcode.try(:name)
  end

  def target_electorate_mp
    (electorate = most_populous_electorate_for_postcode) &&
    electorate.mps.first.try(:full_name)
  end

  def target_electorate_slug
    if electorate = postcode.most_populous_electorate_by_jurisdiction_id(9)
      if electorate.issue
        electorate.name.downcase.gsub(/ /, '_')
      elsif ['NSW', 'VIC', 'TAS', 'QLD', 'WA', 'SA'].include? postcode.state
        "#{postcode.state.downcase}_#{SenateHtvs.senate_issue_for_electorate(electorate)}"
      end
    end
  end

  def volunteer_at_booths(booth_data_key, email_id, link_only: false, split: nil)
    electorates = postcode.try(:electorates)
    booth_data = []
    if electorates.present? && (merge = Merge.find_by_name(booth_data_key))
      merge_records = MergeRecord.where('join_id in (?)', electorates.map(&:name)).where(merge_id: merge.id, name: 'booth_data').order(:id)
      booth_data = merge_records.map{|record|
        name, slug = record.value.split('|')
        { name: name, slug: slug }
      }
    end
    booth_data = [{name: 'a booth near you', slug: 'electionday'}] if booth_data.empty?
    if split
      splits = booth_data.each_slice((booth_data.length * split).ceil).to_a
      booth_data = splits[(random * splits.length).floor]
    end
    booth_data.map{|booth|
      link = "http://www.getup.org.au/#{booth[:slug]}?t=#{EmailTrackingToken.encode(id, email_id)}"
      html = "<p><a href='#{link}'"
      if !link_only
        html += " style='background-color:#FA4B18;margin:2px;border:12px solid #FA4B18;border-radius:7px;" +
               "display:inline-block;font-family:sans-serif;font-size:20px;font-weight:bold;line-height:25px;" +
               "text-align:center;text-decoration:none;width:400px;color:#ffffff;letter-spacing:2px;-webkit-text-size-adjust:none;'"
      end
      html += ">Volunteer at #{booth[:name]}</a></p>"
    }.join('')
  end

  protected

  def most_populous_electorate_for_postcode
    postcode && postcode.most_populous_electorate_by_jurisdiction_id(9)
  end
end
