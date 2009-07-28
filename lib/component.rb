class Component
  include ActionView::Helpers::AssetTagHelper
  attr_accessor :id, :name, :controller, :thumbnail

  def self.all
    index = 0
    @components ||= Dir.glob("app/controllers/components/**/*.rb").collect {|path|
      path = path.gsub("app/controllers/components/", "")
    }.compact.sort.collect {|path|
      returning Component.new(path) do |component|
        component.id = index = index + 1
      end
    }
  end

  def self.find(index)
    all[index.to_i - 1]
  end

  def self.categories
    all.inject({}) {|h, obj| obj.get_controller.component_categories?.each {|i| h[i] ||= []; h[i] << obj }; h }
  end

  def initialize(path)
    @name = path.gsub('.rb', '')
    @controller = "components/#{@name}".camelize.constantize.to_s
    @name.gsub!(/_controller$/, '')
    @thumbnail = image_path("/images/components/#{@name}.png")
  end
  
  def get_controller
    @controller.constantize
  end
  
  def to_param
    id.to_s
  end
end
