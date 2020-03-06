#!/usr/bin/env ruby

require 'aws-sdk'
require 'dotenv'
require 'git'
require 'logger'
require 'thor'

module Hashicorptools
  class CodeDeploy < Thor

    desc 'deploy', 'deploy latest code to environment'
    option :environment, :required => true
    option :branch, default: 'master'
    option :aws_region, default: 'us-east-1'
    option :commit
    def deploy
      g = Git.open('..')

      commit = if options[:commit].present?
                 g.gcommit(options[:commit])
               else
                 g.checkout(options[:branch].to_sym)
                 g.log.first
               end


      puts "deploying commit: #{commit.sha} #{commit.message}"

      create_deployment(commit.sha, commit.message)
    end

    private

    def create_deployment(commit_id, commit_message = nil)
      Dotenv.load

      client = Aws::CodeDeploy::Client.new(region: options[:aws_region])
      response = client.create_deployment({
                                            application_name: application_name,
                                            deployment_group_name: "#{application_name}-#{options[:environment]}",
                                            revision: {
                                              revision_type: 'GitHub',
                                              git_hub_location: {
                                                repository: "controlshift/#{application_name}",
                                                commit_id: commit_id
                                              }
                                            },
                                            description: (commit_message || "commit #{commit_id}").slice(0,99)
                                          })
      puts "created deployment #{response.deployment_id}"
      puts "https://console.aws.amazon.com/codedeploy/home?region=#{options[:aws_region]}#/deployments/#{response.deployment_id}"
    end

    def application_name
      raise "implement me"
    end
  end
end
