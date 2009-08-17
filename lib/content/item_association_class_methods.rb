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
      content_type = (options[:content_type] && options[:content_type].is_a?(String) && options[:content_type].constantize) || 
        (options[:content_type] && options[:content_type]) || Content::Item

      if options.has_key?(:foreign_key)
        ignored_attributes << name_ids

        define_method(name_ids) do |*args|
          instance_variable_set("@#{name}_loaded".to_sym, false)
          self[name] = nil
          opts = args.first || {}
          opts[:conditions] ||= {}
          opts[:conditions][options[:foreign_key]] = self.id
          opts[:id_only] = true
          if args.length == 0
            self[name_ids] ||= content_type.find :all, opts
          else
            content_type.find :all, opts
          end
        end

        define_method(name) do |*args|
          instance_variable_set("@#{name}_loaded".to_sym, true)
          self[name_ids] = nil
          opts = args.first || {}
          opts[:conditions] ||= {}
          opts[:conditions][options[:foreign_key]] = self.id
          if args.length == 0
            self[name] ||= content_type.find :all, opts
          else
            content_type.find :all, opts
          end
        end
      else
        define_method(name_ids) do
          if instance_variable_get("@#{name}_loaded".to_sym)
            self[name_ids] = self[name].collect(&:id)
            self[name] = nil
            instance_variable_set("@#{name}_loaded".to_sym, false)
          else
            if self[name_ids].nil?
              self[name_ids] = []
            else
              self[name_ids] = ActiveSupport::JSON.decode(self[name_ids]) if self[name_ids].is_a? String
            end
          end
          self[name_ids]
        end

        define_method("#{name_ids}=".to_sym) do |val|
          self[name] = nil
          instance_variable_set("@#{name}_loaded".to_sym, false)
          if val.nil? or val.is_a? Array
            self[name_ids] = val
          elsif val.is_a? Content::Item
            self[name_ids] = [val.id.to_i] 
          else
            self[name_ids] = [val.to_i]
          end
        end unless options[:readonly]

        define_method(name) do
          ary = self[name]
          if ary.nil?
            self[name] = ary = content_type.get(self.send(name_ids) || [])
            instance_variable_set("@#{name}_loaded".to_sym, true)
            self[name_ids] = nil
          end
          ary
        end

        define_method("#{name}=".to_sym) do |val|
          if val.nil?
            instance_variable_set("@#{name}_loaded".to_sym, false)
            self[name] = nil
            self[name_ids] = nil
          elsif val.is_a? Array
            instance_variable_set("@#{name}_loaded".to_sym, true)
            self[name] = val
            self[name_ids] = nil
          end
        end unless options[:readonly]

        define_method("#{name}_loaded".to_sym) do
          instance_variable_get("@#{name}_loaded".to_sym)
        end
      end
    end

    def belongs_to(name, options = {})
      raise "name must be singular" unless name.to_s == name.to_s.singularize
      name_id = "#{name}_id".to_sym
      other_ids = "#{options[:foreign_key].to_s.singularize}_ids".to_sym if options.has_key?(:foreign_key)
      ignored_attributes << name
      serialized_attributes << name_id
      content_type = (options[:content_type] && options[:content_type].is_a?(String) && options[:content_type].constantize) || 
        (options[:content_type] && options[:content_type]) || Content::Item

      define_method(name_id) do
        self[name_id].to_i
      end

      define_method(name) do
        self[name] ||= content_type.find(self[name_id].to_i) unless self[name_id].to_i == 0
      end

      define_method("#{name_id}=".to_sym) do |val|
        # Remove from other list
        if !other_ids.nil?
          other = self.send(name)
          if !other.nil?
            other.send(other_ids).reject! {|item| item == self.id }
            other.save!
          end
        end

        if val.nil?
          self[name] = nil
          self[name_id] = nil
        elsif val.is_a? content_type
          if !other_ids.nil?
            save! if new_record?
            val.send(other_ids) << self.id
            val.send(other_ids).uniq!
            val.save!
          elsif val.new_record?
            val.save!
          end
          self[name] = val
          self[name_id] = val.id.to_i 
        else
          self[name_id] = val.to_i
        end
      end

      define_method("#{name}=".to_sym) do |val|
        # Remove from other list
        if !other_ids.nil?
          other = self.send(name)
          if !other.nil?
            other.send(other_ids).reject! {|item| item == self.id }
            other.save!
          end
        end

        if val.nil?
          self[name] = nil
          self[name_id] = nil
        elsif val.is_a? content_type
          if !other_ids.nil?
            save! if new_record?
            val.send(other_ids) << self.id
            val.send(other_ids).uniq!
            val.save!
          elsif val.new_record?
            val.save!
          end
          self[name] = val
          self[name_id] = val.id.to_i
        else
          self[name_id] = val.to_i
        end
      end
    end

    alias :has_one :belongs_to

    def field(name_or_ary, field_type = :string)
      names = name_or_ary
      names = [name_or_ary] unless name_or_ary.is_a? Array
      names.each do |name|
        serialized_attributes << name
        field_klass = field_type.to_s.camelcase.constantize

        define_method(name) do
          if !self[name].is_a?(field_klass) and self[name].is_a? String and !self[name].blank?
            if field_klass == Symbol
              @attributes[name] = self[name].to_sym
            elsif field_klass == Time
              @attributes[name] = Time.parse(self[name])
            else
              @attributes[name] = ActiveSupport::JSON.decode(self[name])
            end
          end
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
