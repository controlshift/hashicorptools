# Generated by juwelier
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Juwelier::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: hashicorptools 0.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "hashicorptools".freeze
  s.version = "0.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nathan Woodhull".freeze]
  s.date = "2020-07-17"
  s.description = "Wrappers for terraform and packer".freeze
  s.email = "systems@controlshiftlabs.com".freeze
  s.executables = ["ec2_host".freeze]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  s.files = [
    ".ruby-gemset",
    ".ruby-version",
    ".travis.yml",
    "Gemfile",
    "LICENSE",
    "README.md",
    "Rakefile",
    "VERSION",
    "bin/ec2_host",
    "hashicorptools.gemspec",
    "lib/hashicorptools.rb",
    "lib/hashicorptools/ami_configs/standard-ami.json",
    "lib/hashicorptools/auto_scaling_group.rb",
    "lib/hashicorptools/code_deploy.rb",
    "lib/hashicorptools/ec2_utilities.rb",
    "lib/hashicorptools/host.rb",
    "lib/hashicorptools/packer.rb",
    "lib/hashicorptools/update_launch_configuration.rb",
    "lib/hashicorptools/variables.rb",
    "spec/hashicorptools_spec.rb",
    "spec/spec_helper.rb"
  ]
  s.homepage = "http://github.com/woodhull/hashicorptools".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Wrappers for terraform and packer".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<aws-sdk>.freeze, ["~> 2"])
    s.add_runtime_dependency(%q<dynect_rest>.freeze, ["= 0.4.6"])
    s.add_runtime_dependency(%q<aws-sdk-v1>.freeze, ["~> 1.67"])
    s.add_runtime_dependency(%q<dotenv>.freeze, ["~> 2.2", ">= 2.2.1"])
    s.add_runtime_dependency(%q<thor>.freeze, ["= 0.20.0"])
    s.add_runtime_dependency(%q<activesupport>.freeze, ["~> 5.1", ">= 5.1.4"])
    s.add_runtime_dependency(%q<byebug>.freeze, ["~> 10.0", ">= 10.0.2"])
    s.add_runtime_dependency(%q<git>.freeze, ["~> 1.3"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.7"])
    s.add_development_dependency(%q<rdoc>.freeze, ["~> 3.12"])
    s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0"])
    s.add_development_dependency(%q<juwelier>.freeze, ["~> 2.4", ">= 2.4.7"])
    s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
  else
    s.add_dependency(%q<aws-sdk>.freeze, ["~> 2"])
    s.add_dependency(%q<dynect_rest>.freeze, ["= 0.4.6"])
    s.add_dependency(%q<aws-sdk-v1>.freeze, ["~> 1.67"])
    s.add_dependency(%q<dotenv>.freeze, ["~> 2.2", ">= 2.2.1"])
    s.add_dependency(%q<thor>.freeze, ["= 0.20.0"])
    s.add_dependency(%q<activesupport>.freeze, ["~> 5.1", ">= 5.1.4"])
    s.add_dependency(%q<byebug>.freeze, ["~> 10.0", ">= 10.0.2"])
    s.add_dependency(%q<git>.freeze, ["~> 1.3"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.7"])
    s.add_dependency(%q<rdoc>.freeze, ["~> 3.12"])
    s.add_dependency(%q<bundler>.freeze, ["~> 2.0"])
    s.add_dependency(%q<juwelier>.freeze, ["~> 2.4", ">= 2.4.7"])
    s.add_dependency(%q<simplecov>.freeze, [">= 0"])
  end
end

