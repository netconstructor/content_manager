module Content
  module ItemAssociationClassMethods
    def ignored_attributes
      @ignored_attributes ||= []
    end
    
    def serialized_attributes
      @serialized_attributes ||= []
    end

    def has_many(name, options = {})
      raise "name must be plural" unless name.to_s == name.to_s.pluralize
      name_ids = "#{name.to_s.singularize}_ids".to_sym
      ignored_attributes << name
      serialized_attributes << name_ids

      define_method(name_ids) do
        self[name_ids] ||= []
      end

      define_method("#{name_ids}=".to_sym) do |val|
        if val.is_a? Content::Item
          self[name_ids] = [val.id.to_i] 
        elsif !val.is_a? Array
          self[name_ids] = [val.to_i]
        else
          self[name_ids] = val.to_i
        end
      end

      define_method(name) do
        ary = self[name]
        if ary.nil?
          self[name] = ary = (self[name_ids] || []).collect {|id| self.class.find(id.to_i) }
        end
        ary
      end

      define_method("#{name}=".to_sym) do |val|
        if val.is_a? Array
          self[name_ids] = val
        end
      end
    end

    def belongs_to(name, options = {})
      raise "name must be singular" unless name.to_s == name.to_s.singularize
      name_id = "#{name}_id".to_sym
      ignored_attributes << name
      serialized_attributes << name_id

      define_method(name_id) do
        self[name_id].to_i
      end

      define_method("#{name_id}=".to_sym) do |val|
        if val.is_a? Content::Item
          self[name] = val
          self[name_id] = val.id.to_i 
        else
          self[name_id] = val.to_i
        end
      end

      define_method(name) do
        self[name] ||= self.class.find(self[name_id].to_i)
      end

      define_method("#{name}=".to_sym) do |val|
        if val.is_a? Content::Item
          val.save! if val.new_record?
          self[name] = val
          self[name_id] = val.id.to_i
        end
      end
    end

    alias :has_one :belongs_to

    def field(name_or_ary, field_type = :string)
      names = name_or_ary
      names = [name_or_ary] unless name_or_ary.is_a? Array
      names.each do |name|
        serialized_attributes << name

        define_method(name) do
          self[name]
        end

        define_method("#{name}=".to_sym) do |val|
          self[name] = val
        end

        define_method("#{name}_changed?".to_sym) do
          self.changed_attributes.has_key? name
        end

        define_method("#{name}_change".to_sym) do
          [self.changed_attributes[name], self[name]] if self.changed_attributes.has_key? name
        end

        define_method("#{name}_was".to_sym) do
          if self.changed_attributes.has_key? name
            self.changed_attributes[name]
          else
            self[name]
          end
        end
      end
    end

    def fields(*names)
      field names
    end
    
    def index(name, index_type = :lexical)
      self.connection.set_index name, index_type
    end
  end
end
