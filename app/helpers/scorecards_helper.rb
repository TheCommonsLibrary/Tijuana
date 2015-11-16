module ScorecardsHelper


  def stars(score)
    if score.present?
      # eg: builds array like [:good, :good, :bad, :bad, :bad, :none]
      stars = score.inject([]) do |acc, (type, count)| 
        acc + star(type, count)
      end

      html = ""
      # iterate through two at a time
      stars.each_slice(2) do |a, b|
        html += self.send "#{a}_#{b}"
      end
      html.html_safe
    else
      "No Policy"
    end
  end

  private

  def star(type, count)
    (count * 2).to_i.times.map{type}
  end

  def good_none
    '<div class="score-half-left"><i class="icon-star good"></i></div>'\
    '<div class="score-half-right"><i class="icon-circle-blank"></i></div>'
  end

  def bad_none
    '<div class="score-half-left"><i class="icon-star bad"></i></div>'\
    '<div class="score-half-right"><i class="icon-circle-blank"></i></div>'
  end

  def good_bad
    "<div><i class='icon-star-half good right'></i>" \
    "<i class='icon-star-half bad icon-flip-horizontal'></i></div>"
  end

  def good_good
    "<div><i class='icon-star good'></i></div>"
  end

  def none_none
    "<div class='none'><i class='icon-circle-blank'></i></div>"
  end

  def bad_bad
    "<div><i class='icon-star bad'></i></div>"
  end
end
