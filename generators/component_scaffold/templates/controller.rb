class <%= controller_class_name %>Controller < ComponentController
  component_config :categories => [:general], :containers => [:left, :contents, :right]
  resource_controller_with_help
end
