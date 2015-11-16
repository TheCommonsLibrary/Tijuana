desc 'import actions into AK demo site from tijuana. USAGE: rake import_to_ak[tijuana_page_id, ak_page_name]'
task :import_to_ak, [:tijuana_page_id, :ak_page_name] => :environment do |t, args|
  uri = URI('https://roboticdogs.actionkit.com/rest/v1/action/')
  conn = Net::HTTP.new(uri.hostname, uri.port)
  conn.use_ssl = true


  page_id = args[:tijuana_page_id]
  UserEmail.includes(:user).where(page_id: page_id).each do |email|
    req = Net::HTTP::Post.new(uri)
    req['Content-type'] = 'application/json; charset=utf-8'
    req.basic_auth 'getup2016', 'S6HnEiuv'
    data = {page: args[:ak_page_name], 
            email: email.user.email, 
            first_name: email.user.first_name, 
            last_name: email.user.last_name, 
            action_email_subject: email.subject, 
            action_email_body: email.body, 
            action_email_targets: email.targets
    }

    req.set_form_data(data)
    res = conn.request(req)
    case res
    when Net::HTTPSuccess, Net::HTTPRedirection
      puts "Completed OK"
    else
      puts "ERROR"
      puts res.code
      puts res.body
    end

  end

  conn.finish if conn.started?

end
