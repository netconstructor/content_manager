class ContentScaffoldGenerator < Rails::Generator::NamedBase
  default_options :skip_timestamps => true, :skip_migration => true

  attr_reader   :controller_name,
                :controller_class_path,
                :controller_file_path,
                :controller_class_nesting,
                :controller_class_nesting_depth,
                :controller_class_name,
                :controller_underscore_name,
                :controller_singular_name,
                :controller_plural_name
  alias_method  :controller_file_name,  :controller_underscore_name
  alias_method  :controller_table_name, :controller_plural_name

  def initialize(runtime_args, runtime_options = {})
    super

    if @name == @name.pluralize
      logger.warning "Plural version of the model detected, using singularized version.  Override with --force-plural."
      @name = @name.singularize
    end

    @controller_name = "content/#{@name}".pluralize

    base_name, @controller_class_path, @controller_file_path, @controller_class_nesting, @controller_class_nesting_depth = extract_modules(@controller_name)
    @controller_class_name_without_nesting, @controller_underscore_name, @controller_plural_name = inflect_names(base_name)
    @controller_singular_name = base_name.singularize
    if @controller_class_nesting.empty?
      @controller_class_name = @controller_class_name_without_nesting
    else
      @controller_class_name = "#{@controller_class_nesting}::#{@controller_class_name_without_nesting}"
    end
  end

  def manifest
    record do |m|
      # Check for class naming collisions.
      m.class_collisions("#{controller_class_name}Controller", "#{controller_class_name}Helper")
      m.class_collisions(class_name)

      # Controller, helper, views, test and stylesheets directories.
      m.directory(File.join('app/models', controller_class_path))
      m.directory(File.join('app/controllers', controller_class_path))
      m.directory(File.join('app/views', controller_class_path, controller_file_name))
      m.directory(File.join('app/views/errors'))
      m.directory(File.join('app/views/sublayouts'))
      m.directory(File.join('public/stylesheets', controller_class_path))

      for action in scaffold_views
        m.template(
          "view_#{action}.erb",
          File.join('app/views', controller_class_path, controller_file_name, "#{action}.html.erb")
        )
      end

      m.template(
        'controller.rb', File.join('app/controllers', controller_class_path, "#{controller_file_name}_controller.rb")
      )

      m.template 'model.rb', File.join('app/models/content', class_path, "#{file_name}.rb")
    end
  end

  protected
    # Override with your own usage banner.
    def banner
      "Usage: #{$0} component_scaffold ModelName [field:type, field:type]"
    end

    def add_options!(opt)
    end

    def scaffold_views
      %w[ _form ]
    end

    def model_name
      class_name.demodulize
    end
end
