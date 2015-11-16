module DynamicAttributes

  def initialize_with_extra_args(arg1 = nil, arg2 = nil)
    initialize_without_extra_args(arg1)
  end

  alias_method_chain :initialize, :extra_args

end