class List < ActiveRecord::Base
  validate :internal_rules

  after_initialize do
    self.rules ||= []
  end
  serialize :rules

  has_many :list_intermediate_results
  belongs_to :blast

  def get_sql_query_string_for_dashboard_user
    combine_relations.select("DISTINCT(users.id)").to_sql
  end

  def combine_relations
    return User.where("users.is_member = true") if rules.blank?
    relation = (rules.inject(nil) do |acc, rule|
        acc = acc.nil? ? rule.to_relation : acc.merge(rule.to_relation)
    end)
    relation = relation.where("users.is_member = true")
    has_agra_rule? ? relation.where("users.is_agra_member = true") : relation
  end

  def filter_by_rules
    filter_by_rules_and_relation(nil)
  end

  def filter_by_rules_and_relation(additional_relation)
    relations = combine_relations
    relations = relations.merge(additional_relation) if additional_relation
    execute_query(relations.select("DISTINCT(users.id)")).to_a.flatten
  end

  def filter_by_rules_excluding_users_from_push(push, options={})
    exclude_users_rule = ListCutter::ExcludeUsersRule.new(:push_id => push.id)

    relation = combine_relations.select("DISTINCT(users.id)").merge(exclude_users_rule.to_relation)

    # exclude users matching active dark filters
    DarkFilter::DarkFilter.where(active_filter: true).each do |dark_filter|
      relation = relation.merge(dark_filter.filter(push.campaign))
    end

    if options[:limit].is_a? Fixnum
      relation = relation.order(:random).limit(options[:limit])
    end
    if !options[:no_jobs].blank? && options[:no_jobs] > 1
      relation = relation.select("MOD(FLOOR(users.id / 10), #{options[:no_jobs]||1}) modulus").having("modulus = #{options[:current_job_id]||0}")
    end
    results = execute_query(relation)
    id_idx = results.fields.index "id"
    results.map {|row| row[id_idx]}
  end

  def method_missing(sym, *args, &block)
    /^set\_([a-z_]+\_rule)$/.match(sym) do |match|
      rule_class = "ListCutter::#{match[1].camelcase}".constantize
      add_or_update_rule(rule_class.new(*args))
      return
    end
    super(sym, *args, &block)
  end

  def count_stats_and_store_on(intermediate_result)
    relations = combine_relations
    size = 0
    benchmark = Benchmark.measure { size = execute_query(relations.select("COUNT(DISTINCT(users.id)) AS count")).first.first }
    total_time = benchmark.total
    data = {size: size, total_time: sprintf("%.4f", total_time), sql: relations.select('DISTINCT(users.id)').to_sql}
    intermediate_result.update_attributes!(data: data, list: self, ready: true)
    rescue Exception => ex
      intermediate_result.update_attributes!(data: {error: ex.to_s}, list: self, ready: true)
    ensure
      intermediate_result.id
  end

  def latest_user_count
    if list_intermediate_results.size > 0
      list_intermediate_results.last.data && list_intermediate_results.last.data[:size]
    else
      nil
    end
  end

  def include_quarantine_members?
    !rules.detect { |rule| rule.instance_of? ListCutter::ExcludeQuarantineRule}
  end

  def include_low_volume_members?
    !rules.detect { |rule| rule.instance_of? ListCutter::ExcludeLowVolumeMembersRule}
  end

private

  def get_custom_rule 
    rules.detect {|rule| rule.is_custom? }
  end

  def has_agra_rule?
    rules.any? {|rule| rule.has_agra_rule? } 
  end

  def execute_query(relation)
    ReadonlyDatabase.connection.execute(relation.to_sql)
  end

  def internal_rules
    rules.each do |rule|
      errors.add(get_key(rule), rule.errors.messages) if rule.invalid?
    end
  end

  def get_key(rule)
    rule.class.name.underscore.split("/")[1].to_sym
  end

  def add_or_update_rule(rule)
    index = rules.index {|r| r.class == rule.class}
    if index
      rules[index] = rule
    else
      rules << rule
    end
  end
end
