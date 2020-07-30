#!/usr/bin/env ruby

require 'aws-sdk-codedeploy'
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
      output "created deployment #{response.deployment_id}"
      output "https://console.aws.amazon.com/codedeploy/home?region=#{aws_region}#/deployments/#{response.deployment_id}"
    end

    private

    def application_name
      raise "implement me"
    end

    def output(text)
      puts "[#{aws_region}] #{text}"
    end
  end

  class CodeDeploy < Thor
    AWS_REGION_US_EAST_1 = 'us-east-1'

    desc 'deploy', 'deploy latest code to environment'
    option :environment, required: true
    option :branch
    option :aws_regions, type: :array
    option :commit
    def deploy
      g = Git.open('..')

      # We set defaults (depending on environment) for aws_regions if not passed in
      aws_regions = options[:aws_regions] || default_regions

      commit = if options[:commit].present?
                 g.gcommit(options[:commit])
               else
                 branch = options[:branch].nil? ? :main : options[:branch].to_sym
                 g.checkout(branch)
                 g.log.first
               end

      puts "Deploying to environment #{options[:environment]} - regions: #{aws_regions.join(', ')}
            commit: #{commit.sha}
            message: #{commit.message}"

      puts "Deploying for regions: #{aws_regions}"

      threads = []
      aws_regions.each_slice(2) do |aws_regions_batch|
        puts "Deploying for batch of regions: #{aws_regions_batch}"
        aws_regions_batch.each do |aws_region|
          thread = Thread.new{ region_deployment(aws_region).create_deployment(commit.sha, commit.message) }
          threads.push(thread)
        end

        threads.each_with_index do |thread, index|
          begin
            thread.join
          rescue Exception => e
            # Don't quit whole program on exception in thread, just print exception and exit thread
            puts "[#{aws_regions[index]}] EXCEPTION: #{e}"
          end
        end
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
