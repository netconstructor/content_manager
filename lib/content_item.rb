class ContentItem
  attr_accessor :attributes

  def self.establish_connection(name)
    @@connection = Rufus::Tokyo::Table.new("db/#{name}.tdb", "create")
  end

  def self.connection()
    @@connection ||= self.establish_connection('contents')
  end

  def self.mock_attr(*syms)
    syms.each do |sym|
      define_method(sym) { "#{attributes[sym.to_s]}" }
      define_method("#{sym.to_s}=".to_sym) { |val| attributes[sym.to_s] = val }
    end
  end

  def self.wrap_result(attrs)
    attrs.nil? ? nil : ContentItem.new(attrs)
  end

  def self.find_first_by_url(url)
    wrap_result connection[url]
  end

  def self.find_all_by_url(url)
    [self.find_first_by_url(url)]
  end

  def self.find(options)
    options ||= {}
    connection.query { |q|
      (options[:conditions] || {}).each { |cond| q.add_condition cond.key, :eq, cond.value }
      (options[:order] || []).each {|order| q.order_by order }
    }
  end

  def self.polymorphic_finder(which, name, *arguments)
    hash = (connection.query {|q| q.add_condition name.to_s, :eq, arguments.first.to_s })
    hash = hash.first if which == :first
    wrap_result hash 
  end

  def self.method_missing(name, *arguments)
    if name.to_s =~ /^find_all(_by)?_(.+)$/
      polymorphic_finder(:all, $2, arguments)
    elsif name.to_s =~ /^find_(first_by|by)_(.+)$/
      polymorphic_finder(:first, $2, arguments)
    else
      super
    end
  end

  def initialize(attrs = {})
    self.attributes = {}
    (attrs || {}).each { |key, value| self.attributes[key.to_s] = value.to_s }
  end
  
  def save()
    hash = self.attributes.dup
    url = hash.delete "url"
    ContentItem.connection[url] = hash
  end
  
  def to_yaml
    attributes.to_yaml
  end
  
  def to_json
    attributes.to_json
  end
  
  def method_missing(name, *arguments)
    if arguments.length > 0
      attributes[name.to_s.chomp('=')] = arguments.first
    elsif attributes.has_key? name.to_s
      attributes[name.to_s]
    else
      super
    end
  end

  mock_attr :id, :status, :version, :url, :heading, :summary, :content_type, :sublayout
end
