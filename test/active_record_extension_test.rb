require File.join(File.dirname(__FILE__), 'test_helper')

class FilterAttrTest < Test::Unit::TestCase
  def teardown
    # we need to leave attributes clear after each test
    TestAR.write_inheritable_attribute("attr_accessible", nil)
    TestAR.write_inheritable_attribute("attr_protected", nil)
  end

  for word in %w(accessible protected)
    class_eval <<-END

    def test_active_record_should_respond_to_with_attr_#{word}
      assert_respond_to(ActiveRecord::Base, :with_attr_#{word})
    end

    def test_with_attr_#{word}_should_yield
      yielded = false
      ActiveRecord::Base.with_attr_#{word} {yielded = true}
      assert yielded, "with_attr_#{word} should yield"
    end

    def test_with_attr_#{word}_should_not_affect_mass_assignment_outside_the_block
      TestAR.with_attr_#{word}(:foo) {}
      ar = TestAR.new(:foo => 'foo', :bar => 'bar')
      assert_equal('foo', ar.foo)
      assert_equal('bar', ar.bar)
    end

    def test_with_attr_#{word}_should_set_#{word}_attributes_inside_the_block
      TestAR.attr_#{word}(:mass)
      TestAR.with_attr_#{word}(:foo, :bar) do
        assert_equal(['foo', 'bar'].to_set, TestAR.#{word}_attributes)
      end
    end

    def test_with_attr_#{word}_should_not_affect_#{word}_attributes_outside_the_block
      TestAR.attr_#{word}(:mass)
      TestAR.with_attr_accessible(:foo, :bar) {}
      TestAR.with_attr_protected(:charge, :spin) {}
      assert_equal(['mass'].to_set, TestAR.#{word}_attributes)
    end

    def test_with_attr_#{word}_should_reraise_exception_raised_in_the_block
      assert_raises(LoadError) do 
        TestAR.with_attr_#{word}(:foo) {raise LoadError}
      end
    end

    def test_with_attr_#{word}_should_leave_everything_the_same_after_exception
      TestAR.attr_accessible(:mass)
      TestAR.attr_protected(:spin)
      begin
        TestAR.with_attr_#{word}(:foo) {raise LoadError}
      rescue Exception
      end
      assert_equal(['mass'].to_set, TestAR.accessible_attributes)
      assert_equal(['spin'].to_set, TestAR.protected_attributes)
    end
    END
  end

  def test_with_attr_accessible_should_allow_mass_assignment_of_selected_attrs_inside_the_block
    TestAR.with_attr_accessible(:foo, :bar) do
      ar = TestAR.new(:foo => 'foo', :bar => 'bar')
      assert_equal('foo', ar.foo)
      assert_equal('bar', ar.bar)
    end
  end

  def test_with_attr_accessible_should_prevent_mass_assignment_of_unselected_attrs_inside_the_block
    TestAR.with_attr_accessible(:foo, :bar) do
      ar = TestAR.new(:foo => 'foo', :bar => 'bar', :spin => 'spin')
      assert_nil(ar.spin)
    end
  end

  def test_with_attr_protected_should_allow_mass_assignment_of_unselected_attrs_inside_the_block
    TestAR.with_attr_protected(:foo, :bar) do
      ar = TestAR.new(:foo => 'foo', :bar => 'bar', :spin => 'spin')
      assert_equal('spin', ar.spin)
    end
  end

  def test_with_attr_protected_should_prevent_mass_assignment_of_selected_attrs_inside_the_block
    TestAR.with_attr_protected(:foo, :bar) do
      ar = TestAR.new(:foo => 'foo', :bar => 'bar', :spin => 'spin')
      assert_nil(ar.foo)
      assert_nil(ar.bar)
    end
  end

  private

  class TestAR < ActiveRecord::Base
    # We override columns method so we don't need a connection to the database
    def self.columns
      %w(foo bar charge mass spin).map do |col_name|
        ActiveRecord::ConnectionAdapters::Column.new(col_name, nil, 'string')
      end
    end
  end
end
