module Admin::ListCutterHelper
  def rules_for_form
    [
      {label: "Country",                   class: ListCutter::CountryRule},
      {label: "Domain",                    class: ListCutter::EmailDomainRule},
      {label: "Postcodes",                 class: ListCutter::PostcodeWithinRule},
      {label: "States and Territories",    class: ListCutter::StateTerritoryRule},
      {label: "Donation Frequency",        class: ListCutter::DonorRule},
      {label: "Campaigns",                 class: ListCutter::CampaignRule},
      {label: "Pillars",                   class: ListCutter::PillarRule},
      {label: "Electorates",               class: ListCutter::ElectorateRule},
      {label: "Number of Actions Taken",   class: ListCutter::ActionTakenRule},
      {label: "Email status",              class: ListCutter::EmailActionRule},
      {label: "{OLD} - User Tags",         class: ListCutter::OldTaggedUsersRule},
      {label: "User Tags",                 class: ListCutter::TaggedUsersRule},
      {label: "CommunityRun User",         class: ListCutter::AgraRoleRule},
      {label: "CommunityRun Campaign",     class: ListCutter::AgraSlugRule},
      {label: "Custom SQL",                class: ListCutter::CustomSqlRule},
      {label: "Email Address List",        class: ListCutter::EmailAddressesRule},
      {label: "Email Tracking Token List", class: ListCutter::TokensRule},
      {label: "Email Frequency",           class: ListCutter::EmailFrequencyRule},
      {label: "Member Value - Money",      class: ListCutter::MemberValueMoneyRule},
      {label: "Member Value - Time",       class: ListCutter::MemberValueTimeRule},
      {label: "Member Value - Voice",      class: ListCutter::MemberValueVoiceRule},
      {label: "No Email Sent Today",       class: ListCutter::NoEmailSentTodayRule},
    ].sort {|a,b| a[:label] <=> b[:label] }
  end

  def error_for(model, key)
    model.errors[key].inject("") do |acc, msg|
      acc << "<span class=\"error\">#{msg}</span>"
    end
  end


  def get_rule(list, rule_class)
    list.rules.select {|r| r.class == rule_class}.first || rule_class.new
  end

  def electorate_select_options
    Electorate.all.inject({}) do |acc, e|
      acc[e.name] = e.id
      acc
    end
  end

  def federal_electorates
    electorates = Electorate.joins(:jurisdiction).where(jurisdictions: {code: 'FEDERAL'})
    electorates.collect { | electorate | [electorate.name, electorate.id] }.to_a
  end

  def postcode_options
    postcodes = Postcode.order(:number).all
    postcodes.collect {|postcode| [postcode.number, postcode.id]}.to_a
  end
end
