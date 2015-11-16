module JurisdictionFind

  def jurisdiction
    @jurisdiction ||= jurisdiction_code.blank? ? Jurisdiction.find_by_code("FEDERAL") : Jurisdiction.find_by_code(jurisdiction_code)
  end

end
