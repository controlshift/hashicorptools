#!/usr/bin/env ruby

require 'aws-sdk'
require 'dotenv'
require 'git'
require 'logger'
require 'thor'

module Hashicorptools
  class RegionDeployment
    attr_accessor :aws_region, :environment

    def initialize(aws_region:, environment:)
      @aws_region = aws_region
      @environment = environment
    end

    def create_deployment(commit_id, commit_message)
      Dotenv.load

      client = Aws::CodeDeploy::Client.new(region: aws_region)
      response = client.create_deployment({
                                            application_name: application_name,
                                            deployment_group_name: "#{application_name}-#{@environment}",
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
      puts "https://console.aws.amazon.com/codedeploy/home?region=#{aws_region}#/deployments/#{response.deployment_id}"
    end

    private

    def application_name
      raise "implement me"
    end
  end

  class CodeDeploy < Thor
    AWS_REGION_US_EAST_1 = 'us-east-1'

    desc 'deploy', 'deploy latest code to environment'
    option :environment, :required => true
    option :branch
    option :aws_regions, :type => :array
    option :commit
    def deploy
      g = Git.open('..')

      # We set defaults (depending on environment) for aws_regions if not passed in
      aws_regions = options[:aws_regions] || default_regions

      # TODO restore defaulting branch to the default branch (and remove below check)
      # once all the repos have the same default branch name of `main`
      # Currently, `agra` is using `master` while other apps are using `main`.
      # and we are unable to detect what the default branch is
      # via the git client here.
      if options[:commit].nil? && options[:branch].nil?
        raise 'You must supply either commit or branch to deploy'
      end

      commit = if options[:commit].present?
                 g.gcommit(options[:commit])
               else
                 g.checkout(options[:branch].to_sym)
                 g.log.first
               end

      aws_regions.each do |aws_region|
        puts "deploying to environment #{options[:environment]} region #{aws_region},
              commit: #{commit.sha}
              #{commit.message}"
        region_deployment(aws_region).create_deployment(commit.sha, commit.message)
      end
    end

    private

    def region_deployment(aws_region)
      RegionDeployment.new(aws_region: aws_region, environment: options[:environment])
    end

    def default_regions
      [AWS_REGION_US_EAST_1]
    end
  end
end
