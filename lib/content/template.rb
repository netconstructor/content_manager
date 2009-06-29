module Content
  class Template < Content::Item
    field :components
    field :sublayout
    field :contents, :array
    validates_length_of :heading, :minimum => 5
    validates_presence_of :sublayout

    def template
      self
    end

    def set_container(name, contents)
      instance_variable_set "@#{name}_obj".to_sym, ActiveSupport::JSON.encode(contents)
    end

    def get_container(name)
      ivar = "@#{name}_obj".to_sym
      obj = instance_variable_get(ivar) or returning ActiveSupport::JSON.decode(self[name]) do
        instance_variable_set ivar, obj
      end
    end
  end
end
