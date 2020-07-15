module Hashicorptools
  NUMBER_OF_AMIS_TO_KEEP = 2

  class Packer < Thor
    include Ec2Utilities
    include Variables

    def self.exit_on_failure?
      true
    end

    desc "build", "creates an AMI from the current config"
    option :debug, :required => false
    def build
      _build
    end

    desc "validate", "validates the packer config"
    def validate
      system "packer validate #{ami_config_path}"
    end

    desc "fix", "runs the packer fix cmd"
    def fix
      system "packer fix #{ami_config_path}"
    end

    desc "console", "interactive session"
    def console
      require 'byebug'
      byebug
    end

    desc "list", "list all available amis"
    def list
      amis_in_region(region).each do |ami|
        puts ami.image_id
      end
    end

    desc "clean", "clean old AMIs that are no longer needed"
    def clean
      clean_amis
    end

    desc "clean_snapshots", "clean obsolete EBS snapshots not associated with any AMI"
    def clean_snapshots
      snapshots = ec2.snapshots.with_owner('self')
      snapshots.each do |snapshot|
        match = snapshot.description.match(/Created by CreateImage\(.+\) for (ami-[0-9a-f]+) from vol-.+/)
        if match.nil?
          puts "Skipping #{snapshot.id} - #{snapshot.description}"
          next
        end

        ami_id = match[1]
        unless ec2.images[ami_id].exists?
          puts "Removing obsolete snapshot #{snapshot.id} - #{snapshot.description}"
          snapshot = AWS::EC2::Snapshot.new(snapshot.id)
          snapshot.delete
        end
      end
    end

    desc "boot", "start up an instance of the latest version of AMI"
    def boot
      run_instances_resp = ec2.run_instances(image_id: current_ami('base-image').image_id,
        min_count: 1,
        max_count: 1,
        instance_type: "t2.micro")

      ec2.create_tags( resources: run_instances_resp.instances.collect(&:instance_id),
          tags: [ {key: 'Name', value: "packer test boot #{tag_name}"},
                  {key: 'environment', value: 'packer-development'},
                  {key: 'temporary', value: 'kill me'}])

      require 'byebug'
      byebug
    end

    protected

    def _build(settings_overrides={})
      settings_overrides.merge!({source_ami: source_ami_id, vpc_id: ami_building_vpc_id, subnet_id: ami_building_subnet_id, ami_tag: tag_name, cookbook_name: cookbook_name})

      if options[:debug]
        puts "[DEBUG] Executing 'packer build -debug #{variables(settings_overrides)} #{ami_config_path}'"
        system "packer build -debug \
          #{variables(settings_overrides)} \
          #{ami_config_path}" or exit(1)
      else
        system "packer build \
          #{variables(settings_overrides)} \
          #{ami_config_path}" or exit(1)
      end

      clean_amis
    end

    def source_ami_id
      current_ami('base-image').image_id
    end

    def ami_building_vpc_id
      vpc_with_name('ami-building').vpc_id
    end

    def ami_building_subnet_id
      ec2.client.describe_subnets({filters: [{name: "vpc-id", values: [ami_building_vpc_id]}]}).subnet_set.first.subnet_id
    end

    def format_variable(key, value)
      "-var '#{key}=#{value}'"
    end

    def tag_name
      raise 'implement me'
    end

    def cookbook_name
      raise 'implement me'
    end

    def ami_config_path
      File.expand_path('../ami_configs/standard-ami.json', __FILE__)
    end

    def region
      'us-east-1'
    end

    def auto_scaling
      @auto_scaling ||= Aws::AutoScaling::Client.new(region: region)
    end

    def ec2_v2
      @ec2 ||= Aws::EC2::Client.new(region: region)
    end

    def amis_in_use
      launch_configs = auto_scaling.describe_launch_configurations
      image_ids = launch_configs.data['launch_configurations'].collect{|lc| lc.image_id}.flatten

      ec2_reservations = ec2_v2.describe_instances
      image_ids << ec2_reservations.reservations.collect{|res| res.instances.collect{|r| r.image_id}}.flatten
      image_ids.flatten
    end

    def ami_regions
      ['us-east-1', 'eu-central-1']
    end

    def clean_amis
      ami_regions.each do |ami_region|
        clean_amis_for_region(ami_region)
      end
    end

    def clean_amis_for_region(region_to_clean)
      ami_ids = amis_in_region(region_to_clean).collect{|a| a.image_id}
      ami_ids_to_remove = ami_ids - amis_in_use
      potential_amis_to_remove = amis_in_region(region_to_clean)
      potential_amis_to_remove.keep_if {|a| ami_ids_to_remove.include?(a.image_id) }

      if potential_amis_to_remove.size > NUMBER_OF_AMIS_TO_KEEP
        amis_to_remove = potential_amis_to_remove[NUMBER_OF_AMIS_TO_KEEP..-1]
        amis_to_keep = potential_amis_to_remove[0..(NUMBER_OF_AMIS_TO_KEEP-1)]

        puts "Deregistering old AMIs in #{region_to_clean}..."
        amis_to_remove.each do |ami|
          ebs_mappings = ami.block_device_mappings
          puts "Deregistering #{ami.image_id}"
          ami.deregister
          delete_ami_snapshots(ebs_mappings, snapshot_region: region_to_clean)
        end

        puts "Currently active AMIs..."
        amis_to_keep.each do |ami|
          puts ami.image_id
        end
      else
        puts "no AMIs to clean in #{region_to_clean}."
      end
    end

    def amis_in_region(ami_region)
      regional_ec2_client = AWS::EC2.new(region: ami_region)

      sort_by_created_at( regional_ec2_client.images.with_owner('self').with_tag('Name', tag_name).to_a )
    end

    def delete_ami_snapshots(ebs_mappings, snapshot_region:)
      regional_ec2_client = AWS::EC2::Client.new(region: snapshot_region)
      ebs_mappings.each do |volume, attributes|
        puts "Deleting snapshot #{attributes[:snapshot_id]}"
        regional_ec2_client.delete_snapshot(snapshot_id: attributes[:snapshot_id])
      end
    end
  end
end
