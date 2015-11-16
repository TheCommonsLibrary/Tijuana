FactoryGirl.define do
  factory :member_value_time, class: MemberValue do |mv|
    mv.user                { create(:user)  }
    mv.current              {false}
    mv.value_type          {"time"}
    mv.cumulative_value          {1}
    mv.delta_value           {1}
    mv.updated_at          { generate(:time) }
    mv.created_at          { generate(:time) }
  end
  
  factory :member_value_money, class: MemberValue do |mv|
    mv.user                { create(:user)  }
    mv.current              {false}
    mv.value_type          {"money"}
    mv.cumulative_value          {1000}
    mv.delta_value           {1000}
    mv.updated_at          { generate(:time) }
    mv.created_at          { generate(:time) }
  end
  
  factory :member_value_voice, class: MemberValue do |mv|
    mv.user                { create(:user)  }
    mv.current              {false}
    mv.value_type          {"voice"}
    mv.cumulative_value          {1}
    mv.delta_value           {1}
    mv.updated_at          { generate(:time) }
    mv.created_at          { generate(:time) }
  end
end