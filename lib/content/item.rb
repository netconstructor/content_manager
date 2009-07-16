module Content
	class Item
    extend ItemAssociationClassMethods
    extend ItemFinderClassMethods
    extend ItemClassMethods
    
    fields :status, :version, :url, :heading, :summary, :content_type
    belongs_to :template

    def initialize(attrs = {})
      @attributes = { :content_type => self.class.name.to_s }
      @attributes.merge!(attrs.symbolize_keys) unless attrs.nil?
      @new_record = !@attributes.has_key?(:__id)
      yield(self) if block_given?
    end

    def save
      create_or_update
    end

    def create_or_update
      raise ActiveRecord::ReadOnlyRecord if readonly?
      result = new_record? ? create : update
      result != false
    end

    def create
      self[:__id] = self.class.connection.genuid if self[:__id].nil?
      if new_record? or changed?
        saved_attributes = {}
        self.class.ignored_attributes.each {|k| self["#{k.to_s.singularize}_ids"] = self[k].collect(&:id) if instance_variable_get("@#{k}_loaded".to_sym) }
        @attributes.each {|k,v| saved_attributes[k] = v.is_a?(String) ? v : v.to_json unless self.class.ignored_attributes.include?(k) }
        self.class.connection.save_record(self.class, self.id, saved_attributes)
        @new_record = false
        changed_attributes.clear
      end
      self
    end
    alias update create
    alias respond_to_without_attributes? respond_to?

    def save!
      save
      nil
    end

    def destroy
      self.class.connection.delete_record_by_id self.class, id
    end

    def readonly?
      false
    end

    def new_record?
      @new_record
    end

    def changed?
      !changed_attributes.empty?
    end

    def [](key)
      read_attribute key
    end

    def []=(key, value)
      write_attribute key, value
    end

    def read_attribute(attr_name)
      @attributes[attr_name.to_sym]
    end

    def write_attribute(attr_name, value)
      sym = attr_name.to_sym
      if !new_record? and (@attributes[sym].nil? or @attributes[sym] != value)
        attribute_will_change!(sym)
      end
      if value.nil?
        @attributes.delete sym
      else
        @attributes[sym] = value
      end
    end

    def query_attribute(attr_name)
      value = read_attribute(attr_name.to_sym)
      if Numeric === value || value !~ /[^0-9]/
        !value.to_i.zero?
      else
        return false if ActiveRecord::ConnectionAdapters::Column::FALSE_VALUES.include?(value)
        !value.blank?
      end
    end

    def update_attributes(attrs)
      unless attrs.nil?
        attrs.each do |key, value|
          self[key.to_sym] = value
        end
      end
      save
    end

    def method_missing(name, *arguments)
      if arguments.length == 0
        self[name] if @attributes.has_key? name
      elsif arguments.length == 1 and name.to_s.match(/^(.+)=$/)
        self[$1.to_sym] = arguments.first
      else
        super
      end
    end

    def to_param
      id.to_s
    end

    def to_yaml(options = nil)
      @attributes.to_yaml(options)
    end

    def to_json(options = nil)
      @attributes.to_json(options)
    end
    
    def to_xml(options = {}) 
      xml = Builder::XmlMarkup.new(:indent => options[:indent])
      xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
      xml.tag!(self.class.name.underscore.gsub('/', '-').dasherize) do |inner_xml|
        self.class.serialized_attributes.each {|attr_name| inner_xml.tag! attr_name, @attributes[attr_name] unless @attributes[attr_name].nil? }
        yield(inner_xml) if block_given?
      end
      xml.target!
    end

    def id
      self[:__id].to_i unless self[:__id].nil?
    end

  private
    def changed_attributes
      @changed_attributes ||= {}
    end
	end
end

Content::Item.class_eval do
  include Content::ItemDirtyMethods
  include ActiveRecord::Validations
  include ActiveRecord::Callbacks
end
