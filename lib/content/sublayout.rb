module Content
  class Sublayout
    attr_accessor :id, :path, :name, :containers

    def self.all
      index = 0
      @sublayouts ||= Dir.glob("app/views/sublayouts/**/*.erb").collect {|path|
        path = path.gsub("app/views/sublayouts/", "")
        path unless path.match '/_' or path == "application.html.erb"
      }.compact.collect {|path|
        Sublayout.new(path)
      }.collect {|sublayout| 
        if sublayout.containers.length > 0
          sublayout.id = index = index + 1
          sublayout 
        end
      }.compact
    end

    def self.find(index)
      all[index.to_i - 1]
    end

    def self.find_by_path(path)
      all.reject {|item| item.path != path }.first
    end

    def initialize(path)
      @path = path
      @name = @path.gsub('.html.erb', '').gsub('/', ' > ').humanize.titleize
      @containers = returning [] do |tainers|
        File.open("app/views/sublayouts/#{@path}", File::RDONLY) do |fd|
          fd.each do |line|
            tainers << ($2 || "layout").to_sym if line =~ /yield[ \t]*(\(?[ \t]*:([a-z]+)[ \t]*\)?)?%/i
          end
        end
      end
    end
    
    def to_param
      id.to_s
    end
  end
end