# RAILS4 delete this
# this is needed b/c rspec 3 verifies stubs & rails 3 didn't implement respond_to? properly
# http://stackoverflow.com/questions/33399015/rspec-stub-throws-wrong-number-of-arguments-error
module Rails
  class Railtie
    class Configuration
      def respond_to?(name, include_private = false)
        super || @@options.key?(name.to_sym)
      end
    end
  end
end
