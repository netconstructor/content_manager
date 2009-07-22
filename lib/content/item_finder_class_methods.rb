module Content
  module ItemFinderClassMethods
    # Find operates with four different retrieval approaches:
    #
    # * Find by id - This can either be a specific id (1), a list of ids (1, 5, 6), or an array of ids ([5, 6, 10]).
    #   If no record can be found for all of the listed ids, then RecordNotFound will be raised.
    # * Find first - This will return the first record matched by the options used. These options can either be specific
    #   conditions or merely an order. If no record can be matched, +nil+ is returned. Use
    #   <tt>Model.find(:first, *args)</tt> or its shortcut <tt>Model.first(*args)</tt>.
    # * Find last - This will return the last record matched by the options used. These options can either be specific
    #   conditions or merely an order. If no record can be matched, +nil+ is returned. Use
    #   <tt>Model.find(:last, *args)</tt> or its shortcut <tt>Model.last(*args)</tt>.
    # * Find all - This will return all the records matched by the options used.
    #   If no records are found, an empty array is returned. Use
    #   <tt>Model.find(:all, *args)</tt> or its shortcut <tt>Model.all(*args)</tt>.
    #
    # All approaches accept an options hash as their last parameter.
    #
    # ==== Parameters
    #
    # * <tt>:conditions</tt> - An SQL fragment like "administrator = 1", <tt>[ "user_name = ?", username ]</tt>, or <tt>["user_name = :user_name", { :user_name => user_name }]</tt>. See conditions in the intro.
    # * <tt>:order</tt> - An SQL fragment like "created_at DESC, name".
    # * <tt>:limit</tt> - An integer determining the limit on the number of rows that should be returned.
    # * <tt>:offset</tt> - An integer determining the offset from where the rows should be fetched. So at 5, it would skip rows 0 through 4.
    # * <tt>:select</tt> - By default, this is "*" as in "SELECT * FROM", but can be changed if you, for example, want to do a join but not
    #   include the joined columns. Takes a string with the SELECT SQL fragment (e.g. "id, name").
    #
    # ==== Examples
    #
    #   # find by id
    #   Person.find(1)       # returns the object for ID = 1
    #   Person.find(1, 2, 6) # returns an array for objects with IDs in (1, 2, 6)
    #   Person.find([7, 17]) # returns an array for objects with IDs in (7, 17)
    #   Person.find([1])     # returns an array for the object with ID = 1
    #   Person.find(1, :conditions => "administrator = 1", :order => "created_on DESC")
    #
    # Note that returned records may not be in the same order as the ids you
    # provide since database rows are unordered. Give an explicit <tt>:order</tt>
    # to ensure the results are sorted.
    #
    # ==== Examples
    #
    #   # find first
    #   Person.find(:first) # returns the first object fetched by SELECT * FROM people
    #   Person.find(:first, :conditions => [ "user_name = ?", user_name])
    #   Person.find(:first, :conditions => [ "user_name = :u", { :u => user_name }])
    #   Person.find(:first, :order => "created_on DESC", :offset => 5)
    #
    #   # find last
    #   Person.find(:last) # returns the last object fetched by SELECT * FROM people
    #   Person.find(:last, :conditions => [ "user_name = ?", user_name])
    #   Person.find(:last, :order => "created_on DESC", :offset => 5)
    #
    #   # find all
    #   Person.find(:all) # returns an array of objects for all the rows fetched by SELECT * FROM people
    #   Person.find(:all, :conditions => [ "category IN (?)", categories], :limit => 50)
    #   Person.find(:all, :conditions => { :friends => ["Bob", "Steve", "Fred"] }
    #   Person.find(:all, :offset => 10, :limit => 10)
    #   Person.find(:all, :include => [ :account, :friends ])
    #   Person.find(:all, :group => "category")
    #
    def find(*args)
      options = {}
      which = args.shift
      if which.is_a? Symbol
        given_options = args.shift
        options.merge!(given_options) unless given_options.nil?
      else
        id = which
        which = :first
        given_options = args.shift
        options.merge!(given_options) unless given_options.nil?
      end

      options[:limit] = 1 if which == :first

      if id.nil?
        unless name == "Content::Item"
          options[:conditions] ||= {}
          options[:conditions][:content_type] = name
        end
        wrap_result which, connection.run_query(self, options)
      elsif id.is_a? Array
        id.collect {|one_id| find_by_id one_id}.compact
      elsif options.keys.length <= 1
        find_by_id id
      else
        if options.has_key? :conditions
          options[:conditions].merge!(:__id => id)
        else
          options[:conditions] = {:__id => id}
        end
        wrap_result which, connection.run_query(self, options)
      end
    end

    def count(options = {})
      unless name == "Content::Item"
        options[:conditions] ||= {}
        options[:conditions].merge!(:content_type => name)
      end
      options[:limit] = 10000
      connection.count(self, options)
    end
    
    def paginate(*args)
      options = args.first.dup

      page = (options[:page] || 1).to_i
      options.delete :page

      per_page = (options[:per_page] || 30).to_i
      options.delete :per_page

      total_entries = count(options)

      options[:conditions] = (options[:conditions] || {})
      options[:conditions].merge!(:content_type => name) unless name == "Content::Item"
      options[:limit] = per_page
      options[:offset] = (page - 1) * options[:limit]

      arr = find(:all, options)
      WillPaginate::Collection.create(page, per_page, total_entries) { |pager| pager.replace arr }
    end

    def find_by_id(id)
      wrap_result :first, connection.get_record_by_id(self, id.to_i)
    end
    
    def find_each(options)
      #TODO - run the query
      if block_given?
        #each ... yield(row)
      end
    end

    def all
      if name == "Content::Item"
        find :all
      else
        find_all_by_content_type name
      end
    end

    def first
      if name == "Content::Item"
        find :first
      else
        find_by_content_type name
      end
    end

    def last
      all.last
    end

    def method_missing(name, *arguments, &block)
      name_s = name.to_s
      if name_s =~ /^find_all(_by)?_(.+)$/
        obj = polymorphic_finder :all, $2, arguments
      elsif name_s =~ /^find_by_(.+)$/
        obj = polymorphic_finder :first, $1, arguments
      elsif name_s =~ /^find_last(_by)?_(.+)$/
        obj = polymorphic_finder :last, $2, arguments
      elsif name_s =~ /^find_or_create_by_(.+)$/
        obj = polymorphic_finder :first, $1, arguments
        if obj.nil?
          self.create(arguments, &block)
        end
      elsif name_s =~ /^paginate_by_(.+)$/
        obj = polymorphic_pager $1, arguments
      else
        obj = super
      end
      yield(obj) if !obj.nil? and block_given?
      obj
    end

  protected
    def hash_zip(keys, values, default=nil, &block)
      hash = block_given? ? Hash.new(&block) : Hash.new(default)
      keys.zip(values) { |k,v| hash[k]=v }
      hash
    end

    def polymorphic_finder(which, name, arguments)
      find which, :conditions => hash_zip(name.split(/_and_/).collect(&:to_sym), arguments)
    end

    def polymorphic_pager(name, arguments)
      names = name.split(/_and_/)
      options = arguments.length > names.length ? arguments.last : {}
      if options.has_key? :conditions
        options[:conditions].merge! hash_zip(names, arguments)
      else
        options.merge!({:conditions => hash_zip(names, arguments)})
      end
      paginate options
    end

    def create_item(attrs)
      if attrs.nil?
        nil
      else
        attrs.symbolize_keys!
        if !attrs[:content_type].nil?
          attrs[:content_type].to_s.camelize.constantize.new(attrs)
        elsif self == Content::Item
          Content::Item.new(attrs)
        end
      end
    end

    def wrap_result(which, attrs)
      unless attrs.nil?
        attrs = [attrs] unless attrs.is_a?(Array)
        case which
        when :first then create_item attrs.first
        when :last then create_item attrs.last
        else attrs.collect { |item| create_item(item) }.compact
        end
      end
    end
	end
end
