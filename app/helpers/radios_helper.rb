module RadiosHelper

  def show_if_not_nil value, label
    unless value.nil?
      item=<<-EOF
         <div>#{label}&nbsp<span>#{value}</span></div>
      EOF
    end

    raw(item)
  end

end
