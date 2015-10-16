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
require_relative 'hashicorptools/packer'
require_relative 'hashicorptools/terraform'
require_relative 'hashicorptools/host'
