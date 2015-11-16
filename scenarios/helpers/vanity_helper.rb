module VanityHelper
  def vanity_choose(exp_alt, path = '/')
    visit "#{path}?_vanity=#{fingerprint exp_alt.keys.first, exp_alt.values.first}"
  end

  def visit_with_vanity_alternative(path, experiment, alternative)
    conjunction = path =~ /\?/ ? '&' : '?'
    visit "#{path}#{conjunction}_vanity=#{fingerprint experiment, alternative}"
  end
  
  def fingerprint(exp_name, alt_name)
    raise "No experiment named #{exp_name}" unless experiment = Vanity.playground.experiment(exp_name)
    raise "No alternative named #{alt_name} for experiment named #{exp_name}" unless alternative = experiment.alternative(alt_name)
    return experiment.fingerprint(alternative)
  end

  def choose_experiment_alternative(exp_name, alt_name)
    Vanity.playground.experiment(exp_name).identify { }
    Vanity.playground.experiment(exp_name).chooses(alt_name)
  end
  
  def find_experiment(name)
    all('ul.experiments li.experiment').detect { |li| li.first('h3', :text => name) }
  end
  
  def find_alternative(exp_name, name)
    find_experiment(exp_name).all('tr').detect { |tr| tr.first('code').text == name }
  end
  
  def participant_user_id_exists?(email)
    # only db because no user interface for seeing this data yet
    user = User.find_by_email email
    ActiveRecord::Base.connection.execute("select * from vanity_participants where user_id = #{user.id}").count > 0
  end
end

RSpec.configuration.include VanityHelper, :type => :feature
