require 'bundler/setup'
require 'dotenv'
require 'thor'
require 'active_support/all'
require 'aws-sdk-v1'
require 'aws-sdk'

module Hashicorptools
end

require_relative 'hashicorptools/variables'
require_relative 'hashicorptools/ec2_utilities'
require_relative 'hashicorptools/auto_scaling_group'
require_relative 'hashicorptools/packer'
require_relative 'hashicorptools/host'
require_relative 'hashicorptools/update_launch_configuration'
require_relative 'hashicorptools/code_deploy'
