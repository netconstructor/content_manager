module Content
  module ItemScopeClassMethods
    def scopes
      scope_cache.keys
    end

    def scope_cache
      @scope_cache ||= {}
    end

    def named_scope(name, options = {})
      name = name.to_sym unless name.is_a?(Symbol)
      scope_cache[name] = nil

      sing = class << self; self; end
      if options.is_a?(Hash)
        sing.class_eval { define_method(name) { scope_cache[name] ||= find(:all, options) } }
      else
        sing.class_eval { define_method(name) { scope_cache[name] ||= find(:all) } }
      end
    end
  end
end
