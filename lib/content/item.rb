module Content
	class Item
    extend ItemAssociationClassMethods
    extend ItemFinderClassMethods
    extend ItemClassMethods
    include Comparable
    
    fields :content_type, :version, :url, :heading, :summary, :keywords, :subject
    fields :contributor, :creator, :publisher, :source, :priority
    field :created_at, :time
    field :updated_at, :time
    field :status, :symbol
    field :changefreq, :symbol
    
    belongs_to :template

    def <=>(that)
      self.heading <=> that.heading
    end

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
      if new_record?
        self[:__id] = self.class.connection.genuid
        flatten_associations
        @attributes[:status] ||= :new
        @attributes[:updated_at] = @attributes[:created_at] = Time.now.gmtime
        perform_save
      end
      self
    end

    def update
      if changed?
        flatten_associations
        @attributes[:updated_at] = Time.now.gmtime
        perform_save
      end
      self
    end
    
    def unversioned_update!
      flatten_associations
      perform_save
      nil
    end

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

    def read_attributes
      @attributes
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

    def tag_fields
      [:keywords]
    end

    def tags(which = nil)
      fields = self.__send__(which) unless which.nil?
      (fields || self.tag_fields).collect do |field| 
        val = __send__(field)
        if val.nil?
          []
        elsif val.is_a?(Array)
          val
        elsif val.is_a?(String)
          val.split(",").collect(&:strip)
        else
          [val.to_s]
        end
      end.flatten.uniq
    end

    def facets
      self.tag_fields.inject({}) do |h, field| 
        h[field] = __send__(field) ? __send__(field).split(",").collect(&:strip) : []
        h 
      end
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

    def searchable?
      self.read_attribute(:searchable) || true
    end

    def searchable_fields
      filtered_fields = [:source_id, :source_modified, :source_type, :source_url, :source_urls, :status, :template_id, :warn_level, :client_id, :__id, :photo_ids, :page_ids, :sublayout]
      self.class.field_attributes.keys - filtered_fields
    end

    def cache_key
      version || updated_at.to_s
    end

    def to_param
      id.to_s
    end

    def to_yaml(options = {})
      @attributes.to_yaml(options)
    end

    def to_json(options = {})
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

    def self.validates_uniqueness_of(*attr_names)
      attr_names.each do |attr_name|
        class_eval <<-EOV
          validate :validates_uniqueness_of_#{attr_name}

          def validates_uniqueness_of_#{attr_name}
            if self.class.count(:conditions => {'#{attr_name}' => self.send('#{attr_name}') }) > (self.new_record? ? 0 : 1)
              errors.add('#{attr_name}', "must be unique")
            end
          end
        EOV
      end
    end

    def logger
      ActiveRecord::Base.logger
    end

  private
    def flatten_associations
      self.class.ignored_attributes.each {|k| self["#{k.to_s.singularize}_ids"] = self[k].collect(&:id) if instance_variable_get("@#{k}_loaded".to_sym) }
    end

    def perform_save
      saved_attributes = {}
      @attributes[:version] = @attributes[:updated_at].strftime("%Y%m%d%H%M%S")
      @attributes.each do |k,v| 
        case
        when v.is_a?(String): saved_attributes[k] = v unless v.blank?
        when v.is_a?(Symbol): saved_attributes[k] = v.to_s
        else saved_attributes[k] = v.to_json 
        end unless self.class.ignored_attributes.include?(k) || v.nil?
      end
      self.class.connection.save_record(self.class, self.id, saved_attributes)
      @new_record = false
      changed_attributes.clear
    end
  
    def changed_attributes
      @changed_attributes ||= {}
    end
	end
end

Content::Item.class_eval do
  include Content::ItemDirtyMethods
  extend Content::ItemScopeClassMethods
  include ActiveRecord::Validations
  include ActiveRecord::Callbacks
end

if defined? RSolr
  Content::Item.send(:extend, Content::Solr::ClassMethods)
end

if defined? Paperclip
  Content::Item.send(:include, Paperclip)
  File.send(:include, Paperclip::Upfile)
end
