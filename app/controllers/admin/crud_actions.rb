module Admin
  module CrudActions
    def self.included(controller)
      controller.class_attribute :model_class, :model_name, :parent_model_class, :parent_model_name
      controller.extend(ClassMethods)
    end
    
    module ClassMethods
      def crud_actions_for(model_class, options)
        before_filter :set_model, :if => lambda { params[:id] }
        before_filter :set_parent
        
        self.model_class = model_class
        self.model_name = "#{model_class.name.underscore}"
        if options[:parent]
          self.parent_model_class = options[:parent]
          self.parent_model_name = "#{parent_model_class.name.underscore}"
        end
        
        self.send(:include, Actions)
        define_method(:model) { instance_variable_get("@#{model_name}") }
        define_method(:model=) { |value| instance_variable_set("@#{model_name}", value) }
        define_method(:parent_model) { parent_model_name.blank? ? nil: instance_variable_get("@#{parent_model_name}") }
        define_method(:parent_model=) { |value| instance_variable_set("@#{parent_model_name}", value) unless parent_model_name.blank? }
        define_method(:crud_redirect) { |key| instance_exec(&options[:redirects][key]) }
      end
    end
    
    module Actions      
      ERROR_MESSAGE = "Your changes have NOT BEEN SAVED YET. Please fix the errors below."
      
      def new
        if parent_model
          self.model = parent_model.send(model_name.pluralize).build
        else
          self.model = model_class.new
        end
      end
      
      def edit
      end
      
      def create
        if parent_model
          self.model = parent_model.send(model_name.pluralize).build(params[model_name])
        else
          self.model = model_class.new(params[model_name])
        end
        save_and_redirect(:create, :new)
      end    
      
      def update
        model.attributes = params[model_name]
        save_and_redirect(:update, :edit)
      end  

      def save_record(model, custom_flash)
        model.save
      end
      protected :save_record
    
      def destroy
        model.destroy
        redirect_to crud_redirect(:destroy), :notice => "'#{model.name}' has been deleted."
      end
      
      private

      def save_and_redirect(success_redirect, error_action)
        custom_flash = {}
        if save_record(model, custom_flash)
          update_flash(custom_flash, {notice:"'#{model.name}' has been saved."})
          redirect_to crud_redirect(success_redirect)
        else
          update_flash(custom_flash, {error:ERROR_MESSAGE})
          render :action => error_action
        end
      end

      def update_flash(custom_flash, default_flash)
        new_flash = custom_flash.empty? ? default_flash : custom_flash
        flash.merge!(new_flash)
      end
      
      def set_model
        self.model = find_model
      end

      def find_model
        model_class.find(params[:id])
      end

      def set_parent
        return unless parent_model_class
        self.parent_model = find_parent
      end

      def find_parent
        if parent_id = params["#{parent_model_name}_id"]
          parent_model_class.find(parent_id)
        else
          model.send(parent_model_name)
        end
      end
    end
  end
end
