module ListCutter
  class DonorRule < Rule
    fields :frequencies, :page_ids, :campaign_ids, :active
    validates :frequencies, :presence => {:message => "Please specify a frequency"}
    validate :campaign_ids_numeric, :unless => lambda { self.campaign_ids.blank? }
    validate :page_ids_numeric, :unless => lambda { self.page_ids.blank? }
    validate :campaign_ids_exist, :unless => lambda { self.campaign_ids.blank? }
    validate :page_ids_exist, :unless => lambda { self.page_ids.blank? }
    
    def initialize(params={})
      super
      @params[:active] = "1" if @params[:active].nil?
    end

    def to_relation
      if negate?
        create_is_not_relation
      else
        create_is_relation
      end
    end

    def active?
      !frequencies.blank?
    end

    private

    def create_is_relation
      page_ids = filter_page_ids
      page_relation = "donations.page_id IN (#{page_ids})" if page_ids.present?
      User.joins(:donations).where(create_frequency_relation).where(page_relation)
    end

    def create_is_not_relation
      page_ids = filter_page_ids
      join_fragments = ["LEFT OUTER JOIN donations ON donations.`user_id` = `users`.id"]
      join_fragments << "(#{create_frequency_relation})"
      join_fragments << "donations.page_id IN (#{page_ids})" if page_ids.present?

      User.joins(join_fragments.join(" AND ")).where("donations.id IS NULL")
    end

    def create_frequency_relation
      frequency_one_off = ["donations.frequency IN ('one_off')"]
      frequency_recurring = ["(donations.frequency IN ('#{frequencies.reject{|freq| freq == 'one_off'}.join("','")}') AND donations.active = #{active})"]
      donation_frequency_fragment(frequency_one_off, frequency_recurring).join(" OR ")
    end

    def donation_frequency_fragment(frequency_one_off, frequency_recurring)
      case
        when frequencies.include?('one_off') && frequencies_contains_recurring?
          [frequency_one_off, frequency_recurring]
        when frequencies_contains_recurring?
          [frequency_recurring]
        else
          [frequency_one_off]
      end
    end

    def frequencies_contains_recurring?
      (frequencies & ['weekly', 'monthly', 'annual']).present?
    end

    def filter_page_ids
      page_id_list = find_page_ids_for_campaign_ids || []
      page_id_list << page_ids_array
      page_id_list.compact.join(",")
    end

    def campaign_ids_array
      campaign_ids.split(',').reject(&:blank?).map(&:to_i) if campaign_ids.present?
    end

    def page_ids_array
      page_ids.split(',').reject(&:blank?).map(&:to_i) if page_ids.present?
    end

    def find_page_ids_for_campaign_ids
      if campaign_ids.present?
        page_sequence_id_list = PageSequence.where(campaign_id: campaign_ids_array).map(&:id)
        page_id_list = Page.where(page_sequence_id: page_sequence_id_list).map(&:id)
        page_id_list
      end
    end
    
    def campaign_ids_numeric
      errors.add(:campaign_ids, "Please enter numbers only for campaign ids, comma separated for multiple") unless is_numeric(campaign_ids)
    end

    def page_ids_numeric
      errors.add(:page_ids, "Please enter numbers only for page ids, comma separated for multiple") unless is_numeric(page_ids)
    end

    def is_numeric(field)
      (field =~ /^[\d ,]+$/).present?
    end

    def campaign_ids_exist
      bad_ids = campaign_ids_array.find_all {|id| !Campaign.find_by_id(id)}
      errors.add(:campaign_ids, "Invalid campaign id(s) #{bad_ids.join(", ")}") unless bad_ids.empty?
    end

    def page_ids_exist
      bad_ids = page_ids_array.find_all {|id| !Page.find_by_id(id)}
      errors.add(:page_ids, "Invalid page id(s) #{bad_ids.join(", ")}") unless bad_ids.empty?
    end
  end
end
