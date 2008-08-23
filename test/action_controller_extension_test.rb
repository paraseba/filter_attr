require File.join(File.dirname(__FILE__), 'test_helper')

class TestController < ActionController::Base
  def test_action_1
    @filtered_params = params
    render :nothing => true
  end

  def test_action_2
  end

  def self_filtered
    filter_parameters_map(params, [:name, :mass])
    @filtered_params = params
    render :nothing => true
  end
end

class TestChildController < TestController
end

class TestControllerTest < ActionController::TestCase
  def setup 
    @controller = TestController.new 
    @request = ActionController::TestRequest.new 
    @response = ActionController::TestResponse.new
  end

  def teardown
    TestController.filter_chain.clear
  end

  def test_action_controller_should_respond_to_filter_params
    assert_respond_to(ActionController::Base, :filter_params)
  end

  def test_filter_params_should_raise_if_not_allow_key_is_passed
    assert_raises(ArgumentError) {TestController.filter_params(:only => :foo)}
  end

  def test_filter_params_should_not_raise_if_passed_valid_options
    assert_nothing_raised {TestController.filter_params(:allow => :pepe)}
  end

  def test_filter_params_should_return_hash_with_indifferent_access
    TestController.filter_params :allow => [:foo]
    get :test_action_1, {:foo => 1}
    assert_instance_of(HashWithIndifferentAccess, filtered_params)
  end

   def test_filter_params_should_filter_everything_if_no_allowed_params
     TestController.filter_params :allow => []
     get :test_action_1, {:foo => 1}
     assert_params_equal({})
   end

   def test_filter_params_with_one_filtered_param
     TestController.filter_params :allow => [:foo]
     get :test_action_1, {:foo => 1}
     assert_params_equal :foo => '1'
   end

  def test_filter_params_with_excess_filters_should_ignore_them
    with_allow([:foo, :bar, :charge, :spin], {:foo => 1})
    assert_params_equal :foo => '1'
  end

  def test_filter_params_should_keep_2_params_out_of_3
    with_allow([:foo, :bar, :charge, :spin], {:charge => '-e', :spin => '1/2', :name => 'electron'})
    assert_params_equal :charge => '-e', :spin => '1/2'
  end

  def test_filter_params_should_keep_none_of_3
    with_allow([:foo, :bar, :charge, :spin], {:mass => 'm', :name => 'electron'})
    assert_params_equal({})
  end

  def test_filter_params_should_keep_all
    all_pars = {:bar => '1', :charge => 'e', :spin => '1/2'}
    with_allow([:foo, :bar, :charge, :spin], all_pars.dup)
    assert_params_equal(all_pars)
  end

  def test_filter_params_should_keep_arrays_if_needed
    with_allow([:foo, :bar], {:foo => [1,2]})
    assert_params_equal(:foo => [1, 2])
  end

  def test_filter_params_should_filter_arrays_if_needed
    with_allow([:foo, :bar], {:missing => [1,2]})
    assert_params_equal({})
  end

   def test_filter_params_should_not_filter_single_map_allowed_parameter
     with_allow({:particle => :mass}, :particle => {:mass => 'm'})
     assert_params_equal(:particle => {:mass => 'm'})
   end

  def test_filter_params_should_filter_single_map_disallowed_parameter
    with_allow({:particle => :spin}, :particle => {:mass => 'm'})
    assert_params_equal(:particle => {})
  end

  def test_filter_params_should_filter_array_map_disallowed_parameter
    with_allow({:particle => [:spin, :mass, :charge]}, :particle => {:mass => 'm', :name => 'electron', :charge => 'e'})
    assert_params_equal(:particle => {:mass => 'm', :charge => 'e'})
  end

  def test_filter_params_should_not_filter_map_map_allowed_parameter
    par = {:particle => {:charge => {:positive => '-e', :negative => 'e'}}}
    with_allow({:particle => {:charge => [:positive, :negative]}}, par.dup )
    assert_params_equal(par)
  end

  def test_filter_params_should_filter_map_map_disallowed_parameter
    with_allow({:particle => {:charge => [:positive, :negative]}}, :particle => {:charge => {:positive => '-e', :negative => 'e', :neutral => 0}})
    assert_params_equal(:particle => {:charge => {:positive => '-e', :negative => 'e'}})
  end

  def test_filter_params_should_not_filter_array_map_allowed_paramaters
    par = {:interaction => 'em', :particle => {:charge => {:positive => '-e', :negative => 'e'}}}
    with_allow([:interaction, {:particle => {:charge => [:positive, :negative]}}], par.dup )
    assert_params_equal(par)
  end

  def test_filter_params_should_filter_array_map_disallowed_paramaters
    par = {:interaction => 'em', :particle => {:charge => {:positive => '-e', :negative => 'e', :neutral => '0'}}}
    with_allow([:interaction, {:particle => {:charge => [:positive, :negative]}}], par.dup )
    filtered = {:interaction => 'em', :particle => {:charge => {:positive => '-e', :negative => 'e'}}}
    assert_params_equal(filtered)
  end

  def test_filter_params_should_filter_not_map_parameters_when_map_expected
    with_allow({:particle => {:charge => [:positive, :negative]}}, :particle => {:charge => '-e'})
    assert_params_equal(:particle => {})
  end

  def test_filter_params_should_accept_string_elements_in_models
    par = {:interaction => 'em', :particle => {:charge => {:positive => '-e', :negative => 'e', :neutral => '0'}}}
    with_allow(['interaction', {'particle' => {'charge' => ['positive', 'negative']}}], par.dup )
    filtered = {:interaction => 'em', :particle => {:charge => {:positive => '-e', :negative => 'e'}}}
    assert_params_equal(filtered)
  end

  def test_filter_params_should_honor_only_option
    TestController.filter_params :allow => {}, :only => :test_action_2
    get :test_action_1, {:name => 'electron'}
    assert_params_equal(:name => 'electron')
  end

  def test_filter_params_should_honor_except_option
    TestController.filter_params :allow => {}, :except => :test_action_1
    get :test_action_1, {:name => 'electron'}
    assert_params_equal(:name => 'electron')
  end

  def test_filter_should_work_well_with_inheritance
    @controller = TestChildController.new 
    with_allow({:particle => :spin}, :particle => {:mass => 'm'})
    assert_params_equal(:particle => {})
    @controller = TestController.new 
    with_allow({:particle => :mass}, :particle => {:spin => '1/2'})
    assert_params_equal(:particle => {})
  end

  def test_should_add_filter_parameters_map_method
    get :self_filtered, :name => 'electron', :mass => 'm', :charge => '-e'
    assert_equal({'name' => 'electron', 'mass' => 'm'}, filtered_params)
  end

  private
  def with_allow(allow, params, action = 'test_action_1')
    @controller.class.filter_params :allow => allow
    get action, params
  end

  def assert_params_equal(par, action = 'test_action_1')
    assert_equal(with_base_params(par, action), filtered_params)
  end

  def filtered_params
    assigns['filtered_params']
  end

  def with_base_params(par, action)
    {'controller' => @controller.controller_path, 'action' => action.to_s}.with_indifferent_access.merge(par.with_indifferent_access)
  end

end
