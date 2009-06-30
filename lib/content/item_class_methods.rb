module Content
  module ItemClassMethods
    def establish_connection(options = {})
      conn_options = ::YAML::load_file('config/content.yml')[::RAILS_ENV]
      conn_options.merge!(options) unless options.nil?
      conn_type = conn_options[:type] || conn_options["type"] || :cabinet
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
        :"#{klass.name.underscore}"
      end 
      defaults << name
      defaults.shift.to_s.humanize
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

    def update(id, attributes)
      if id.is_a?(Array)
        idx = -1
        id.collect { |one_id| idx += 1; update(one_id, attributes[idx]) }
      else
        object = find(id)
        object.update_attributes(attributes)
        object
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
  end
end
