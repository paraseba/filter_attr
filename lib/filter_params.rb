module FilterParams
  def self.included(base) #:nodoc:
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
  end

  # <tt>ActionController::Base</tt> will include methods in this module.
  module InstanceMethods
    def filter_parameters_map(params, model)
      self.class.filter_parameters_map(params, model)
    end
  end

  # <tt>ActionController::Base</tt> will extend methods in this module.
  module ClassMethods
    def filter_params(options)
      options = options.dup
      params_model = options.delete(:allow)
      raise ArgumentError, ':allow key needed for ActionController::Base::filter_params' if params_model.nil?
      params_model = [params_model].flatten + ['action', 'controller']

      before_filter(options) do |controller|
        filter_parameters_map(controller.params, params_model)
      end
    end

    def filter_parameters_map(params, model)
      params.dup.each_pair do |key, value|
        if validation = find_parameters_model_validation(key, model)
          if validation.to_s != key
            if value.is_a?(Hash)
              filter_parameters_map(value, [validation].flatten)
              params[key] = value
            else
              params.delete(key)
            end
          end
        else
          params.delete(key)
        end
      end
    end

    private

    def find_parameters_model_validation(key, model)
      for model_item in model
        case model_item
        when Array
          inner = find_parameters_model_validation(key, model_item) and return inner
        when Hash
          inner = find_parameters_model_validation(key, model_item.keys) and return model_item[inner]
        else
          return model_item if model_item.to_s == key
        end
      end
      nil
    end
  end
end
