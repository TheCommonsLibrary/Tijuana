namespace :nation_builder do
  desc "Tidy up staging requestb.in webhooks (test residuals)"
  task "destroy_requestbin_webhooks" => :environment  do |t, args|
    return if !Rails.env.development?
    resp = NationBuilder::Api.call_api :webhooks, :index, {}
    webhook_ids = all_the_things(resp)
    requestbin_webhook_ids = webhook_ids.select{|wh| wh["url"] =~ /requestb\.in/}.map{|wh| wh["id"]}
    puts; puts "destroying webhooks"
    requestbin_webhook_ids.each do |wh_id|
      print "."
      NationBuilder::Api.call_api :webhooks, :destroy, id: wh_id
    end
    puts; puts "#{requestbin_webhook_ids.length} requestbin webhooks destroyed"
  end

  desc "Tidy up temporary lists (test residuals)"
  task "destroy_temporary_lists" => :environment  do |t, args|
    return if !Rails.env.development?
    resp = NationBuilder::Api.call_api :lists, :index, {}
    list_ids = all_the_things(resp)
    temporary_list_ids = list_ids.select{|list| list["name"] =~ /Tijuana\ temporary\ list/}.map{|list| list["id"]}
    puts; puts "destroying lists"
    temporary_list_ids.each do |list_id|
      print "."
      NationBuilder::Api.call_api :lists, :destroy, id: list_id
    end
    puts; puts "#{temporary_list_ids.length} temporary lists destroyed"
  end
end

def all_the_things(response)
  client = NationBuilder::Client.new NATION_BUILDER[:site], NATION_BUILDER[:api_token], retries: 0
  pager = NationBuilder::Paginator.new(client, response)
  puts "fetching pages of items"
  recursor(pager, [])
end

def recursor(pager, items)
  print "."
  pager.next? ? recursor(pager.next, items + pager.body["results"]) : items + pager.body["results"]
end
