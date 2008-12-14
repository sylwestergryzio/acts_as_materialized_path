# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{acts_as_materialized_path}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Sylwester Gryzio"]
  s.date = %q{2008-12-13}
  s.description = %q{This gem uses materizlized path for hierarchy implementation in database}
  s.email = ["sylwester.gryzio@gmail.com"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc"]
  s.files = ["History.txt", "init.rb", "Manifest.txt", "PostInstall.txt", "README.rdoc", "Rakefile", "lib/acts_as_materialized_path.rb", "lib/active_record/acts/materialized_path.rb", "script/console", "script/console.cmd", "script/destroy", "script/destroy.cmd", "script/generate", "script/generate.cmd", "spec/spec_helper.rb", "spec/test_database/database_configuration.yml", "spec/test_database/database_connection.rb", "spec/test_database/migrations.rb", "spec/test_models_spec.rb", "spec/test_models/hierarchy.rb", "spec/spec.opts", "tasks/rspec.rake"]
  s.has_rdoc = true
  s.homepage = %q{}
  s.post_install_message = %q{PostInstall.txt}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{acts_as_materialized_path}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Use it for managing hierarchies in databases}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<newgem>, [">= 1.1.0"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<newgem>, [">= 1.1.0"])
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<newgem>, [">= 1.1.0"])
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end
