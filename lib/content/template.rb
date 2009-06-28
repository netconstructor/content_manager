module Content
  class Template < Content::Item
    field :components
    field :sublayout
    validates_length_of :heading, :minimum => 5
    validates_presence_of :sublayout
  
    def components_hash
      if @components_hash.nil?
        @components_hash = {}
        comps = components.split(';')
        comps.each do |comp|
          defn = comp.split(':')
          @components_hash[defn[0].strip.to_sym] = defn[1].strip.split(',').collect(&:strip).collect {|item|
              lr = item.split("=")
              {lr[0].strip.to_sym => lr[1].strip}
            }
        end
      end
      @components_hash
    end
  end
end
