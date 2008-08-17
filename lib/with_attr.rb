module WithAttr
  def self.included(base) #:nodoc:
    base.extend(ClassMethods)
  end

  # <tt>ActiveRecord::Base</tt> will extend methods in this module.
  module ClassMethods
    # We define both methods +with_attr_accessible+ and +with_attr_protected+
    for word in %w(accessible protected)
      class_eval <<-END
        def with_attr_#{word}(*attributes)
          previous = #{word}_attributes
          write_inheritable_attribute("attr_#{word}", Set.new(attributes.map(&:to_s)))
          begin
            yield
          ensure
            write_inheritable_attribute("attr_#{word}", previous)
          end
        end
      END
    end
  end
end
