require 'yaml'

module ListCutter
  class Rule
    include ActiveModel::Validations
    def self.fields(*fields)
      fields = fields.map(&:to_sym)
      fields.each do |field|
        define_method "#{field}" do
          @params[field]
        end
      end
    end
    
    def self.code
      self.name.demodulize.underscore
    end
    
    def negate?
      @params[:not]
    end

    def initialize(params={})
      @params = params
    end

    def to_yaml(opts = {})
      {self.class.code => @params}.to_yaml(opts)
    end

    def has_agra_rule?
      false
    end
    
    def is_custom?
      true
    end
  end
end
