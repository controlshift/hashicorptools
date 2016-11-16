# Generated by juwelier
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Juwelier::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: hashicorptools 0.0.12 ruby lib

Gem::Specification.new do |s|
  s.name = "hashicorptools"
  s.version = "0.0.12"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Nathan Woodhull"]
  s.date = "2016-11-16"
  s.description = "Wrappers for terraform and packer"
  s.email = "systems@controlshiftlabs.com"
  s.executables = ["ec2_host"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  s.files = [
    ".ruby-gemset",
    ".ruby-version",
    ".travis.yml",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE",
    "README.md",
    "Rakefile",
    "VERSION",
    "bin/ec2_host",
    "data/standard-ami.json",
    "hashicorptools.gemspec",
    "lib/hashicorptools.rb",
    "lib/hashicorptools/auto_scaling_group.rb",
    "lib/hashicorptools/code_deploy.rb",
    "lib/hashicorptools/ec2_utilities.rb",
    "lib/hashicorptools/host.rb",
    "lib/hashicorptools/packer.rb",
    "lib/hashicorptools/terraform.rb",
    "lib/hashicorptools/update_launch_configuration.rb",
    "lib/hashicorptools/variables.rb",
    "spec/hashicorptools_spec.rb",
    "spec/spec_helper.rb"
  ]
  s.homepage = "http://github.com/woodhull/hashicorptools"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.8"
  s.summary = "Wrappers for terraform and packer"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<aws-sdk>, ["~> 2"])
      s.add_runtime_dependency(%q<dynect_rest>, [">= 0"])
      s.add_runtime_dependency(%q<aws-sdk-v1>, [">= 0"])
      s.add_runtime_dependency(%q<dotenv>, [">= 0"])
      s.add_runtime_dependency(%q<thor>, [">= 0"])
      s.add_runtime_dependency(%q<activesupport>, [">= 0"])
      s.add_runtime_dependency(%q<byebug>, [">= 0"])
      s.add_runtime_dependency(%q<git>, [">= 0"])
      s.add_runtime_dependency(%q<rspec>, [">= 0"])
      s.add_runtime_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_runtime_dependency(%q<bundler>, ["~> 1.0"])
      s.add_runtime_dependency(%q<juwelier>, [">= 0"])
      s.add_runtime_dependency(%q<simplecov>, [">= 0"])
      s.add_development_dependency(%q<aws-sdk>, ["~> 2"])
      s.add_development_dependency(%q<dynect_rest>, [">= 0"])
      s.add_development_dependency(%q<aws-sdk-v1>, [">= 0"])
      s.add_development_dependency(%q<dotenv>, [">= 0"])
      s.add_development_dependency(%q<thor>, [">= 0"])
      s.add_development_dependency(%q<activesupport>, [">= 0"])
      s.add_development_dependency(%q<byebug>, [">= 0"])
      s.add_development_dependency(%q<git>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0"])
      s.add_development_dependency(%q<juwelier>, [">= 0"])
      s.add_development_dependency(%q<simplecov>, [">= 0"])
    else
      s.add_dependency(%q<aws-sdk>, ["~> 2"])
      s.add_dependency(%q<dynect_rest>, [">= 0"])
      s.add_dependency(%q<aws-sdk-v1>, [">= 0"])
      s.add_dependency(%q<dotenv>, [">= 0"])
      s.add_dependency(%q<thor>, [">= 0"])
      s.add_dependency(%q<activesupport>, [">= 0"])
      s.add_dependency(%q<byebug>, [">= 0"])
      s.add_dependency(%q<git>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_dependency(%q<bundler>, ["~> 1.0"])
      s.add_dependency(%q<juwelier>, [">= 0"])
      s.add_dependency(%q<simplecov>, [">= 0"])
      s.add_dependency(%q<aws-sdk>, ["~> 2"])
      s.add_dependency(%q<dynect_rest>, [">= 0"])
      s.add_dependency(%q<aws-sdk-v1>, [">= 0"])
      s.add_dependency(%q<dotenv>, [">= 0"])
      s.add_dependency(%q<thor>, [">= 0"])
      s.add_dependency(%q<activesupport>, [">= 0"])
      s.add_dependency(%q<byebug>, [">= 0"])
      s.add_dependency(%q<git>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_dependency(%q<bundler>, ["~> 1.0"])
      s.add_dependency(%q<juwelier>, [">= 0"])
      s.add_dependency(%q<simplecov>, [">= 0"])
    end
  else
    s.add_dependency(%q<aws-sdk>, ["~> 2"])
    s.add_dependency(%q<dynect_rest>, [">= 0"])
    s.add_dependency(%q<aws-sdk-v1>, [">= 0"])
    s.add_dependency(%q<dotenv>, [">= 0"])
    s.add_dependency(%q<thor>, [">= 0"])
    s.add_dependency(%q<activesupport>, [">= 0"])
    s.add_dependency(%q<byebug>, [">= 0"])
    s.add_dependency(%q<git>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<rdoc>, ["~> 3.12"])
    s.add_dependency(%q<bundler>, ["~> 1.0"])
    s.add_dependency(%q<juwelier>, [">= 0"])
    s.add_dependency(%q<simplecov>, [">= 0"])
    s.add_dependency(%q<aws-sdk>, ["~> 2"])
    s.add_dependency(%q<dynect_rest>, [">= 0"])
    s.add_dependency(%q<aws-sdk-v1>, [">= 0"])
    s.add_dependency(%q<dotenv>, [">= 0"])
    s.add_dependency(%q<thor>, [">= 0"])
    s.add_dependency(%q<activesupport>, [">= 0"])
    s.add_dependency(%q<byebug>, [">= 0"])
    s.add_dependency(%q<git>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<rdoc>, ["~> 3.12"])
    s.add_dependency(%q<bundler>, ["~> 1.0"])
    s.add_dependency(%q<juwelier>, [">= 0"])
    s.add_dependency(%q<simplecov>, [">= 0"])
  end
end

