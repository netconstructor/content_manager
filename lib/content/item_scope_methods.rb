module Content
  module ItemScopeMethods
    # Scope parameters to method calls within the block.  Takes a hash of method_name => parameters hash.
    # method_name may be <tt>:find</tt> or <tt>:create</tt>. <tt>:find</tt> parameters may include the <tt>:conditions</tt>, <tt>:joins</tt>,
    # <tt>:include</tt>, <tt>:offset</tt>, <tt>:limit</tt>, and <tt>:readonly</tt> options. <tt>:create</tt> parameters are an attributes hash.
    #
    #   class Article < ActiveRecord::Base
    #     def self.create_with_scope
    #       with_scope(:find => { :conditions => "blog_id = 1" }, :create => { :blog_id => 1 }) do
    #         find(1) # => SELECT * from articles WHERE blog_id = 1 AND id = 1
    #         a = create(1)
    #         a.blog_id # => 1
    #       end
    #     end
    #   end
    #
    # In nested scopings, all previous parameters are overwritten by the innermost rule, with the exception of
    # <tt>:conditions</tt>, <tt>:include</tt>, and <tt>:joins</tt> options in <tt>:find</tt>, which are merged.
    #
    # <tt>:joins</tt> options are uniqued so multiple scopes can join in the same table without table aliasing
    # problems.  If you need to join multiple tables, but still want one of the tables to be uniqued, use the
    # array of strings format for your joins.
    #
    #   class Article < ActiveRecord::Base
    #     def self.find_with_scope
    #       with_scope(:find => { :conditions => "blog_id = 1", :limit => 1 }, :create => { :blog_id => 1 }) do
    #         with_scope(:find => { :limit => 10 })
    #           find(:all) # => SELECT * from articles WHERE blog_id = 1 LIMIT 10
    #         end
    #         with_scope(:find => { :conditions => "author_id = 3" })
    #           find(:all) # => SELECT * from articles WHERE blog_id = 1 AND author_id = 3 LIMIT 1
    #         end
    #       end
    #     end
    #   end
    #
    # You can ignore any previous scopings by using the <tt>with_exclusive_scope</tt> method.
    #
    #   class Article < ActiveRecord::Base
    #     def self.find_with_exclusive_scope
    #       with_scope(:find => { :conditions => "blog_id = 1", :limit => 1 }) do
    #         with_exclusive_scope(:find => { :limit => 10 })
    #           find(:all) # => SELECT * from articles LIMIT 10
    #         end
    #       end
    #     end
    #   end
    #
    # *Note*: the +:find+ scope also has effect on update and deletion methods,
    # like +update_all+ and +delete_all+.
    def with_scope(method_scoping = {}, action = :merge, &block)
      method_scoping = method_scoping.method_scoping if method_scoping.respond_to?(:method_scoping)

      # Dup first and second level of hash (method and params).
      method_scoping = method_scoping.inject({}) do |hash, (method, params)|
        hash[method] = (params == true) ? params : params.dup
        hash
      end

      method_scoping.assert_valid_keys([ :find, :create ])

      if f = method_scoping[:find]
        f.assert_valid_keys(VALID_FIND_OPTIONS)
        set_readonly_option! f
      end

      # Merge scopings
      if [:merge, :reverse_merge].include?(action) && current_scoped_methods
        method_scoping = current_scoped_methods.inject(method_scoping) do |hash, (method, params)|
          case hash[method]
            when Hash
              if method == :find
                (hash[method].keys + params.keys).uniq.each do |key|
                  merge = hash[method][key] && params[key] # merge if both scopes have the same key
                  if key == :conditions && merge
                    if params[key].is_a?(Hash) && hash[method][key].is_a?(Hash)
                      hash[method][key] = merge_conditions(hash[method][key].deep_merge(params[key]))
                    else
                      hash[method][key] = merge_conditions(params[key], hash[method][key])
                    end
                  elsif key == :include && merge
                    hash[method][key] = merge_includes(hash[method][key], params[key]).uniq
                  elsif key == :joins && merge
                    hash[method][key] = merge_joins(params[key], hash[method][key])
                  else
                    hash[method][key] = hash[method][key] || params[key]
                  end
                end
              else
                if action == :reverse_merge
                  hash[method] = hash[method].merge(params)
                else
                  hash[method] = params.merge(hash[method])
                end
              end
            else
              hash[method] = params
          end
          hash
        end
      end

      self.scoped_methods << method_scoping
      begin
        yield
      ensure
        self.scoped_methods.pop
      end
    end

    # Works like with_scope, but discards any nested properties.
    def with_exclusive_scope(method_scoping = {}, &block)
      with_scope(method_scoping, :overwrite, &block)
    end

    # Sets the default options for the model. The format of the
    # <tt>options</tt> argument is the same as in find.
    #
    #   class Person < ActiveRecord::Base
    #     default_scope :order => 'last_name, first_name'
    #   end
    def default_scope(options = {})
      self.default_scoping << { :find => options, :create => (options.is_a?(Hash) && options.has_key?(:conditions)) ? options[:conditions] : {} }
    end

    # Test whether the given method and optional key are scoped.
    def scoped?(method, key = nil) #:nodoc:
      if current_scoped_methods && (scope = current_scoped_methods[method])
        !key || !scope[key].nil?
      end
    end

    # Retrieve the scope for the given method and optional key.
    def scope(method, key = nil) #:nodoc:
      if current_scoped_methods && (scope = current_scoped_methods[method])
        key ? scope[key] : scope
      end
    end

    def scoped_methods #:nodoc:
      Thread.current[:"#{self}_scoped_methods"] ||= self.default_scoping.dup
    end

    def current_scoped_methods #:nodoc:
      scoped_methods.last
    end
  end
end
