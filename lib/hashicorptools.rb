require 'bundler/setup'
require 'dotenv'
require 'thor'
require 'host'
require 'ec2_utilities'
require 'active_support/all'
require 'packer'
require 'terraform'

Dotenv.load
