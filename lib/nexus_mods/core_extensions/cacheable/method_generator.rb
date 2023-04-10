class NexusMods

  module CoreExtensions

    module Cacheable

      # Make the cacheable method generators compatible with methods having kwargs
      # TODO: Remove this core extension when cacheable will be compatible with kwargs
      module MethodGenerator

        private

        # Create all methods to allow cacheable functionality, for a given original method name
        #
        # Parameters::
        # * *original_method_name* (Symbol): The original method name
        # * *opts* (Hash): The options given to the cacheable call
        def create_cacheable_methods(original_method_name, opts = {})
          method_names = create_method_names(original_method_name)
          key_format_proc = opts[:key_format] || default_key_format

          const_get(method_interceptor_module_name).class_eval do
            define_method(method_names[:key_format_method_name]) do |*args, **kwargs|
              key_format_proc.call(self, original_method_name, args, kwargs)
            end

            define_method(method_names[:clear_cache_method_name]) do |*args, **kwargs|
              ::Cacheable.cache_adapter.delete(__send__(method_names[:key_format_method_name], *args, **kwargs))
            end

            define_method(method_names[:without_cache_method_name]) do |*args, **kwargs|
              original_method = method(original_method_name).super_method
              original_method.call(*args, **kwargs)
            end

            define_method(method_names[:with_cache_method_name]) do |*args, **kwargs|
              ::Cacheable.cache_adapter.fetch(__send__(method_names[:key_format_method_name], *args, **kwargs), opts[:cache_options]) do
                __send__(method_names[:without_cache_method_name], *args, **kwargs)
              end
            end

            define_method(original_method_name) do |*args, **kwargs|
              unless_proc = opts[:unless].is_a?(Symbol) ? opts[:unless].to_proc : opts[:unless]

              if unless_proc&.call(self, original_method_name, args)
                __send__(method_names[:without_cache_method_name], *args, **kwargs)
              else
                __send__(method_names[:with_cache_method_name], *args, **kwargs)
              end
            end
          end
        end

      end

    end

  end

end

Cacheable::MethodGenerator.prepend NexusMods::CoreExtensions::Cacheable::MethodGenerator
