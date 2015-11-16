class SenateHtvs

  def self.senate_issue_for_electorate(electorate)
    CUSTOM_ISSUES[electorate.name] || 'renewables'
  end

  def self.for_electorate(electorate)
    state = electorate.state
    parties = ['NSW', 'TAS', 'WA'].include?(state) ? ['alp', 'grn'] : [nil]
    issue = electorate.issue.try(:issue) || senate_issue_for_electorate(electorate)
    issue =  issue == 'hospitals' ? 'health' : issue
    parties.map{|party| {state: state.downcase, issue: issue, party: party} }
  end

  private

  CUSTOM_ISSUES = {
    'Cunningham' => 'hospitals',
    'Hume' => 'hospitals',
    'Newcastle' => 'hospitals',
    'Cowper' => 'hospitals',
    'Forde' => 'hospitals',
    'Ballarat' => 'hospitals',
    'Corio' => 'hospitals',
    'Menzies' => 'hospitals'
  }

end
