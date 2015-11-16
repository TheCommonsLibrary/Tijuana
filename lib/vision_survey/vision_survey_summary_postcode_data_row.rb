class VisionSurveySummaryPostcodeDataRow
  def initialize(row)
    @row = row
  end

  def postcode
    number = @row[1].length == 3 ? "0#{@row[1]}" : @row[1]
    postcode = Postcode.find_by_number(number)
    raise "Unable to find postcode #{number}" unless postcode
    postcode
  end

  def climate_rallies
    return_zero_if_null @row[2]
  end

  def election_volunteers
    return_zero_if_null @row[3]
  end

  def booths_covered
    return_zero_if_null @row[4]
  end

  def num_of_members
    return_zero_if_null @row[5]
  end

  private

  def return_zero_if_null(value)
    value == 'NULL' ? 0 : value
  end
end
