# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{content_manager}
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Seth Yates"]
  s.date = %q{2009-06-30}
  s.email = %q{syates@grandcentralmedia.com.au}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "content_manager.gemspec",
     "doc/created.rid",
     "doc/files/README_rdoc.html",
     "doc/fr_class_index.html",
     "doc/fr_file_index.html",
     "doc/fr_method_index.html",
     "doc/index.html",
     "doc/rdoc-style.css",
     "generators/component_scaffold/USAGE",
     "generators/component_scaffold/component_scaffold_generator.rb",
     "generators/component_scaffold/templates/controller.rb",
     "generators/component_scaffold/templates/model.rb",
     "generators/component_scaffold/templates/style.css",
     "generators/component_scaffold/templates/view_edit.html.erb",
     "generators/component_scaffold/templates/view_index.html.erb",
     "generators/component_scaffold/templates/view_new.html.erb",
     "generators/component_scaffold/templates/view_show.html.erb",
     "generators/content_scaffold/USAGE",
     "generators/content_scaffold/content_scaffold_generator.rb",
     "generators/content_scaffold/templates/controller.rb",
     "generators/content_scaffold/templates/model.rb",
     "generators/content_scaffold/templates/view_edit.html.erb",
     "generators/content_scaffold/templates/view_index.html.erb",
     "generators/content_scaffold/templates/view_new.html.erb",
     "generators/content_scaffold/templates/view_show.html.erb",
     "init.rb",
     "lib/component.rb",
     "lib/content/adapters/base.rb",
     "lib/content/adapters/cabinet_adapter.rb",
     "lib/content/adapters/tyrant_adapter.rb",
     "lib/content/item.rb",
     "lib/content/item_association_class_methods.rb",
     "lib/content/item_class_methods.rb",
     "lib/content/item_dirty_methods.rb",
     "lib/content/item_finder_class_methods.rb",
     "lib/content/manager.rb",
     "lib/content/sublayout.rb",
     "lib/content/template.rb",
     "lib/content_manager.rb",
     "test/content_manager_test.rb",
     "test/test_helper.rb"
  ]
  s.homepage = %q{http://github.com/sethyates/content_manager}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.3}
  s.summary = %q{Content::Manager}
  s.test_files = [
    "test/content_manager_test.rb",
     "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rufus-tokyo>, [">= 0.1.12"])
      s.add_runtime_dependency(%q<actsasflinn-ruby-tokyotyrant>, [">= 0.1.8"])
    else
      s.add_dependency(%q<rufus-tokyo>, [">= 0.1.12"])
      s.add_dependency(%q<actsasflinn-ruby-tokyotyrant>, [">= 0.1.8"])
    end
  else
    s.add_dependency(%q<rufus-tokyo>, [">= 0.1.12"])
    s.add_dependency(%q<actsasflinn-ruby-tokyotyrant>, [">= 0.1.8"])
  end
end
