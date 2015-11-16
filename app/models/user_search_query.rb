class UserSearchQuery
  def initialize(query, query_option, first_name, last_name, card_last_four_digits, admins_only, exact_match)
    @query = query
    @query_option = query_option
    @first_name = first_name
    @last_name = last_name
    @card_last_four_digits = card_last_four_digits
    @admins_only = admins_only
    @exact_match = exact_match
  end

  def self.select_options
    { 'Email' => :email, 'Postcode' => :postcode, 'Suburb' => :suburb, 'Notes' => :notes }
  end

  def add_where_clause(relation, column_name, query)
    wildcard = match_at_the_start ? '' : '%'
    if @exact_match
      relation.where("#{column_name} = ?", query)
    else
      relation.where("#{column_name} LIKE ? ESCAPE '!'", "#{wildcard}#{escape_like_query(query)}%")
    end
  end
  private :add_where_clause

  def match_at_the_start
    !(@query_option == 'notes' || @query_option == 'email')
  end
  private :match_at_the_start

  def escape_like_query(query)
    query.gsub(/[!%_]/) { |x| x == '!' ? '!!!' : '!' + x }
  end
  private :escape_like_query

  def results
    relation = User
    relation = process_query_option(relation)                        if @query.present?
    relation = add_where_clause(relation, 'first_name', @first_name) if @first_name.present?
    relation = add_where_clause(relation, 'last_name', @last_name)   if @last_name.present?
    relation = process_card_last_four_digits_option(relation)        if @card_last_four_digits.present?
    relation = relation.where("is_admin = ?", @admins_only)          if @admins_only

    relation.order("users.id ASC")
  end

  def process_card_last_four_digits_option(relation)
    relation.joins(:donations).where("card_last_four_digits = ?", @card_last_four_digits).group("email")
  end

  def process_query_option(relation)
    if @query_option == 'postcode'
      relation.joins(:postcode).where("number = ?", @query)
    else
      add_where_clause(relation, @query_option, @query)
    end
  end
end
