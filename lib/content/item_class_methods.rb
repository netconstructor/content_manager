module Content
  module ItemClassMethods
    def establish_connection
      conn_options = ::YAML::load_file("#{RAILS_ROOT}/config/content.yml")[::RAILS_ENV]
#      conn_type = conn_options[:type] - non-tyrant adapters not supported at the moment
      conn_type = :tyrant
      $adapter = "content/adapters/#{conn_type}_adapter".camelize.constantize.new(conn_options)
    end

    def connection()
      $adapter ||= establish_connection
    end

    def self_and_descendants_from_active_record#nodoc:
      klass = self
      classes = [klass]
      while klass != klass.base_class  
        classes << klass = klass.superclass
      end
      classes
    rescue
      [self]
    end

    def human_name(options = {})
      defaults = self_and_descendants_from_active_record.map do |klass|
        :"#{klass.name.gsub('Content::', '').gsub('::', ' ').underscore.humanize}"
      end 
      defaults << name
      defaults.shift.to_s.humanize
    end
    
    def base_class
      self
    end

    def human_attribute_name(attr_name)
      attr_name.to_s.humanize
    end

    def create(attributes = nil, &block)
      if attributes.is_a?(Array)
        attributes.collect { |attr| create(attr, &block) }
      else
        object = new(attributes)
        yield(object) if block_given?
        object.save
        object
      end
    end

    #this is diffrent to the instance method create_or_update
    def update_or_create(attributes = {})
      id = attributes.delete(:id)
      conditions = attributes.delete(:conditions)

      returning (id && find_by_id(id)) || find(:first, :conditions => conditions) || new do |record|
        attributes.each_pair { |key, value| record[key] = value }
        record.save
      end
    end

    def update(id, attributes)
      if id.is_a?(Array)
        idx = -1
        id.collect { |one_id| idx += 1; update(one_id, attributes[idx]) }
      else
        returning find(id) { |object| object.update_attributes(attributes) }
      end
    end

    def destroy(id)
      if id.is_a?(Array)
        id.map { |one_id| destroy(one_id) }
      else
        find(id).destroy
      end
    end

    def delete(id)
      destroy id
    end

    def destroy_all!
      all(:limit => count).each{ |i| i.destroy }
      nil
    end

  end
end
