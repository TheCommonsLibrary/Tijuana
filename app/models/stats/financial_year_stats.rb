module Stats
  class FinancialYearStats
    CENTS_IN_A_DOLLAR ||= 100

    def last_financial_year
      if Time.zone.now.month > 7
        {
          :start => Time.local(Time.zone.now.year - 1, 7, 1),
          :end => Time.local(Time.zone.now.year, 6, 30, 23, 59, 59)
        }
      else
        {
          :start => Time.local(Time.zone.now.year - 2, 7, 1),
          :end => Time.local(Time.zone.now.year - 1, 6, 30, 23, 59, 59)
        }
      end
    end

    def activities(type)
      UserActivityEvent.where(
        :activity => type,
        :created_at => last_financial_year[:start]..last_financial_year[:end]
      ).size
    end

    def average_donation_amount
      total_donations / number_of_donations
    end

    def number_of_donations
      Donation.joins(:transactions).where(
        :transactions => {:successful => true},
        :created_at => last_financial_year[:start]..last_financial_year[:end]
      ).size
    end

    def number_of_donors
      User.joins(:donations).where(
        :donations => {
          :created_at => last_financial_year[:start]..last_financial_year[:end]
        }
      ).size
    end

    def average_total_donation_per_donor
      total_donations / number_of_donors
    end

    private

    def total_donations
      Donation.joins(:transactions).where(
        :transactions => {:successful => true},
        :created_at => last_financial_year[:start]..last_financial_year[:end]
      ).sum(:amount_in_cents) / CENTS_IN_A_DOLLAR
    end
  end
end
