module ListCutter
  class PostcodeWithinRule < Rule
    fields :postcode_ids, :within, :no_postcode
    validates :postcode_ids, :presence => { :message => "Please provide one or more postcodes" }, :unless => :no_postcode?
    validates :within, :numericality => { :message => "Distance within has to be a number" }, :if => :within_given?
    validate :only_postcodes_or_no_postcode

    def to_relation
      return User.where(["postcode_id #{is_operator} NULL"]) if no_postcode?
      postcodes = !within_given? ? postcode_ids : get_postcodes_within
      User.where(["users.postcode_id #{in_operator} (?)", postcodes])
    end

    def find_origin(id)
      Postcode.find id
    end
    private :find_origin

    def get_postcodes_within
      postcodes_within = []
      postcode_ids.each do |pid|
        postcodes_within.concat(Postcode.within(within, :origin => find_origin(pid)).map(&:id).uniq)
      end
      postcodes_within.uniq
    end
    private :get_postcodes_within

    def active?
      postcode_ids.present? || no_postcode?
    end

    def no_postcode?
      no_postcode == '1'
    end

    private

    def within_given?
      !within.blank?
    end

    def only_postcodes_or_no_postcode
      errors.add(:message, "Please select EITHER postcodes from the list OR tick unknown postcodes") if (postcode_ids.present? || within_given?) && no_postcode?
    end

    def in_operator
      negate? ? "not in" : "in"
    end

    def is_operator
      negate? ? "is not" : "is"
    end
  end
end
