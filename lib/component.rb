class Component
  attr_accessor :id, :name, :controller

  def self.all
    index = 0
    @components ||= Dir.glob("app/controllers/components/**/*.rb").collect {|path|
      path = path.gsub("app/controllers/components/", "")
    }.compact.collect {|path|
      returning Component.new(path) do |component|
        component.id = index = index + 1
      end
    }
  end

  def self.find(index)
    all[index.to_i - 1]
  end
  
  def self.find_by_category(category)
    @categories ||= all.inject({}) {|h, obj| obj.controller.component_categories?.each {|i| h[i] ||= []; h[i] << obj.controller }; h }
    @categories[category] ||= []
  end

  def initialize(path)
    @name = path.gsub('.rb', '')
    @controller = "components/#{@name}".camelize.constantize
    @name.gsub!(/_controller$/, '')
  end
  
  def to_param
    id.to_s
  end
end
