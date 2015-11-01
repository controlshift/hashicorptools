module Hashicorptools
  NUMBER_OF_AMIS_TO_KEEP = 2

  class Packer < Thor
    include Ec2Utilities
    include Variables

    desc "build", "creates an AMI from the current config"
    option :debug, :required => false
    def build
      _build
    end

    desc "validate", "validates the packer config"
    def validate
      system "packer validate #{ami_config_path}"
    end

    desc "console", "interactive session"
    def console
      ec2 = Aws::EC2::Client.new(region: 'us-east-1')
      require 'byebug'
      byebug
    end

    desc "list", "list all available telize amis"
    def list
      amis.each do |ami|
        puts ami.image_id
      end
    end

    desc "clean", "clean old AMIs that are no longer needed"
    def clean
      clean_amis
    end

    desc "boot", "start up an instance of the latest version of AMI" 
    def boot
      ec2 = Aws::EC2::Client.new(region: 'us-east-1')
      run_instances_resp = ec2.run_instances(image_id: current_ami('base-image').image_id,
        min_count: 1,
        max_count: 1,
        instance_type: "t2.micro")

      ec2.create_tags( resources: run_instances_resp.instances.collect{|i| i.instance_id },
          tags: [ {key: 'Name', value: "packer test boot #{tag_name}"}, {key: 'environment', value: 'packer-development'}, {key: 'temporary', value: 'kill me'}])

      require 'byebug'
      byebug
    end

    protected

    def _build(settings_overrides={})
      settings_overrides.merge!({source_ami: source_ami_id, ami_tag: tag_name, cookbook_name: cookbook_name})

      if options[:debug]
        puts "[DEBUG] Executing 'packer build -debug #{variables(settings_overrides)} #{ami_config_path}'"
        system "packer build -debug \
          #{variables(settings_overrides)} \
          #{ami_config_path}"
      else
        system "packer build \
          #{variables(settings_overrides)} \
          #{ami_config_path}"
      end

      clean_amis
    end

    def source_ami_id
      current_ami('base-image').image_id
    end

    def tag_name
      raise 'implement me'
    end

    def cookbook_name
      raise 'implement me'
    end

    def ami_config_path
      datadir_path = Gem.datadir('hashicorptools').gsub(/\/hashicorptools$/, '')  # workaround for bug in Gem.datadir
      File.join(datadir_path, 'standard-ami.json')
    end

    def clean_amis
      if amis.size > NUMBER_OF_AMIS_TO_KEEP
        amis_to_remove = amis[NUMBER_OF_AMIS_TO_KEEP..-1]
        amis_to_keep = amis[0..(NUMBER_OF_AMIS_TO_KEEP-1)]

        puts "Deregistering old AMIs..."
        amis_to_remove.each do |ami|
          puts "Deregistering #{ami.image_id}"
          ami.deregister
        end

        puts "Currently active AMIs..."
        amis_to_keep.each do |ami|
          puts ami.image_id
        end
      else
        puts "no AMIs to clean."
      end
    end
  end
end
