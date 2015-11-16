class VisionSurveyResultRow
  def initialize(row)
    @row = row
  end

  def user
    user = User.find_by_email(@row[1])
    raise "Unable to find user with email #{@row[1]}" unless user
    user
  end

  def new_details_supplied?
    @row[39] == '1'
  end

  def q4_priority_issue
    case @row[16]
      when 'Asylum Seekers'
        'refugees'
      when 'Climate'
        'climate'
      when 'CSG'
        'csg'
      when 'Democracy - Voting'
        'democracy'
      when 'Forests'
        'forests'
      when 'Indigenous'
        'indigenous'
      when 'Marriage Equality'
        'marriage'
      when 'Media - ABC'
        'abc'
      when 'Medicare'
        'safety-net'
      when 'Online Privacy'
        'privacy'
      when 'Paid Parental Leave'
        'parental-leave'
      when 'Reef'
        'reef'
      when 'Super'
        'super'
      when 'TPP'
        'tpp'
      else
        nil
    end
  end

  def q7_volunteering_open_text
    @row[31]
  end

  def q8_bequest?
    @row[32] == 'Send Info'
  end

  def q9_major_donor?
    @row[33] == 'Yes'
  end

  def q10_facebook
    case @row[34]
      when "I don't use Facebook"
        'no'
      when "I use Facebook"
        'use'
      when "I use Facebook and I 'Like' the GetUp page"
        'like'
      else
        nil
    end
  end

  def q11_youtube
    case @row[35]
      when "I don't use YouTube"
        'no'
      when "I use YouTube"
        'use'
      when "I use YouTUbe and I subscribe to GetUpAus"
        'subscribe'
      else
        nil
    end
  end

  def q12_twitter
    case @row[36]
      when "I don't use Twitter"
        'no'
      when "I use Twitter"
        'use'
      when "I use Twitter and I follow @GetUp"
        'follow'
      else
        nil
    end

  end

  def q13_blogging
    case @row[37]
    when "I didn't know GetUp had a blog"
      'unaware'
    when "I don't have a blog"
      'noblog'
    when "I have a blog"
      'haveblog'
    else
      nil
    end
  end

  def q14_google
    case @row[38]
      when "I don't use Google+"
        'no'
      when "I use Google+"
        'use'
      when "I use Google+ and I follow GetUp"
        'follow'
      else
        nil
    end
  end

  def q18_transparency
    case @row[40]
      when 'Use this survey as a binding mandate from our community about what we should work on this year.'
        'mandate'
      when 'Use this survey as a strong guide, but continue to stay nimble and adapt our plans to keep current with breaking news and events.'
        'guide'
      when 'Use this survey as useful input, but continue to adapt decisions in response to major events.'
        'nimble'
      else
        nil
    end
  end

  def q3_priorities
    priorities = []
    (2..15).each do |i|
      if @row[i] =~ /[1|2|3]/
        case i
          when 2
            priorities << 'refugees'
          when 3
            priorities << 'tpp'
          when 4
            priorities << 'abc'
          when 5
            priorities << 'privacy'
          when 6
            priorities << 'democracy'
          when 7
            priorities << 'climate'
          when 8
            priorities << 'reef'
          when 9
            priorities << 'indigenous'
          when 10
            priorities << 'safety-net'
          when 11
            priorities << 'super'
          when 12
            priorities << 'forests'
          when 13
            priorities << 'csg'
          when 14
            priorities << 'marriage'
          when 15
            priorities << 'parental-leave'
        end
      end
    end
    priorities
  end

  def q6_skills
    skills = []
    (18..30).each do |i|
      if !@row[i].blank?
        skills << @row[i]
      end
    end
    skills
  end
end
