module Content
  class Template < Content::Item
    field :components
    field :sublayout
    field :contents
    validates_length_of :heading, :minimum => 3
    validates_presence_of :sublayout

    def self.all_by_heading
      all(:order => "heading")
    end

    def template
      self
    end

    def set_container(name, contents)
      @attributes[name] = contents.is_a?(String) ? ActiveSupport::JSON.encode(contents) : contents
    end

    def get_container(name)
      if self[name].blank?
        []
      else
        ivar = "@#{name}_obj".to_sym
        obj = instance_variable_get(ivar) or returning(self[name].is_a?(String) ? ActiveSupport::JSON.decode(self[name]) : self[name]) do
          instance_variable_set ivar, obj
        end
      end
    end
  end
end
