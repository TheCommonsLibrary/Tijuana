unless Rails.env.development?

  # Do not run schema dump in production as it is slow
  # with push tables, and we only need this in development

  Rake::TaskManager.class_eval do
    def remove_task(task_name)
      @tasks.delete(task_name.to_s)
    end
  end

  Rake.application.remove_task('db:schema:dump')
  namespace :db do
    namespace :schema do
      task :dump do
        # Overriden to do nothing
      end
    end
  end

end
