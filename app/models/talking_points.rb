module TalkingPoints

  def self.included(base)
    base.has_many :talking_points, :foreign_key => "content_module_id", :order => 'id ASC'
    base.accepts_nested_attributes_for :talking_points
    base.before_validation :delete_empty_talking_points
    base.send :include, InstanceMethods
  end

  module InstanceMethods

    def default_number_of_talking_points(n)
      blanks_needed = n - talking_points.length
      blanks_needed.times { self.talking_points.build }
    end

    private

    def delete_empty_talking_points
      talking_points.each do |tp|
        tp.mark_for_destruction if tp.empty?
      end
    end

  end

end