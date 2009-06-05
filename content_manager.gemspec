# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{content_manager}
  s.version = "0.3.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Seth Yates"]
  s.date = %q{2009-06-05}
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
     "init.rb",
     "lib/content_helper.rb",
     "lib/content_item.rb",
     "lib/content_manager.rb",
     "lib/rack/content_manager.rb",
     "rails/init.rb",
     "test/content_manager_test.rb",
     "test/test_helper.rb"
  ]
  s.homepage = %q{http://github.com/sethyates/content_manager}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.3}
  s.summary = %q{Simple Content Manager}
  s.test_files = [
    "test/content_manager_test.rb",
     "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rufus-tokyo>, [">= 0.1.12"])
    else
      s.add_dependency(%q<rufus-tokyo>, [">= 0.1.12"])
    end
  else
    s.add_dependency(%q<rufus-tokyo>, [">= 0.1.12"])
  end
end
