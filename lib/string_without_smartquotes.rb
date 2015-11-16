# encoding: utf-8

class String

  def without_smartquotes
    self.gsub(/“|”/, '"').gsub(/‘|’/, "'")
  end

end