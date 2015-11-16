module SerializedOptionsWithDefaults

  def self.included(target)
    target.class_eval do
      class << self

        def option_field_with_default(name, default)

          option_fields name

          define_method "#{name}_with_default" do
            send("#{name}_without_default") || default
          end

          alias_method_chain name, :default

        end
      end
    end
  end

end
