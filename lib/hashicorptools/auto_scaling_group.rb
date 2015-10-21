require "timeout"

module Hashicorptools
  class AutoScalingGroup
    attr_accessor :name

    def initialize(attrs = {})
      attrs.each do |key,value|
        if self.respond_to?("#{key}=")
          self.send("#{key}=", value)
        end
      end
    end

    def set_desired_instances(desired_instances)
      puts "updating size of #{name} to #{desired_instances}"
      autoscaling.set_desired_capacity({auto_scaling_group_name: name, desired_capacity: desired_instances, honor_cooldown: false })

      # wait for the instance count to be correct.
      wait_until do
        group.instances.size == desired_instances
      end

      groups.each do |group|
        wait_for_activities_to_complete(group)
      end
      puts "all #{desired_instances} scaling activities successful."
      wait_until_instances_ready
      puts "all #{desired_instances} instances ready."
    end

    def wait_until_instances_ready
      groups.each do |group|
        wait_until do
          group = autoscaling.describe_auto_scaling_groups(auto_scaling_group_names: [group.auto_scaling_group_name]).auto_scaling_groups.first
          group.instances.any?
        end

        group = autoscaling.describe_auto_scaling_groups(auto_scaling_group_names: [group.auto_scaling_group_name]).auto_scaling_groups.first
        pending_instance_ids = group.instances.find_all{|i| ['Pending', 'Pending:Wait', 'Pending:Proceed'].include?(i.lifecycle_state) }.collect{|i| i.instance_id}
        shutting_down_ids =  group.instances.find_all{|i| ['Terminating', 'Terminating:Wait', 'Terminating:Proceed'].include?(i.lifecycle_state) }.collect{|i| i.instance_id}
        puts "waiting for #{group.auto_scaling_group_name} #{pending_instance_ids.size} servers to come online, #{shutting_down_ids.size} to terminate."

        if pending_instance_ids.any?
          # wait until all instances are running and returning a good system status check
          ec2.wait_until(:instance_running, instance_ids: pending_instance_ids)
          puts "waiting for instance status checks to pass.."
          wait_until do
            resp = ec2.describe_instance_status(instance_ids: pending_instance_ids)
            resp.instance_statuses.find_all{|s| s.system_status.status != 'ok'}.none?
          end
        end

        ec2.wait_until(:instance_terminated, instance_ids: shutting_down_ids)  if shutting_down_ids.any?
        wait_for_activities_to_complete(group)
      end
    end

    def group
      groups.first
    end

    def delete!
      groups.each do |group|
        wait_for_instances_to_delete(group)

        autoscaling.delete_auto_scaling_group(auto_scaling_group_name: group.auto_scaling_group_name)
        puts "waiting for #{group.auto_scaling_group_name} to delete"

        wait_until do
          autoscaling.describe_auto_scaling_groups(auto_scaling_group_names: [group.auto_scaling_group_name]).auto_scaling_groups.empty?
        end
        autoscaling.delete_launch_configuration(launch_configuration_name: group.launch_configuration_name)
      end
    end

    private

    def wait_for_activities_to_complete(group)
      autoscaling.describe_scaling_activities(auto_scaling_group_name: group.auto_scaling_group_name).activities.each do |activity|
        if activity.status_code != 'Successful' || activity.status_code != 'Cancelled'
          wait_until do
            activity = autoscaling.describe_scaling_activities(auto_scaling_group_name: group.auto_scaling_group_name, activity_ids: [activity.activity_id]).activities.first
            activity.status_code == 'Successful' || activity.status_code == 'Failed' || activity.status_code == 'Cancelled'
          end
        end
      end
    end

    def autoscaling
      @autoscaling ||= Aws::AutoScaling::Client.new(region: 'us-east-1')
    end

    def ec2
      @ec2 ||= Aws::EC2::Client.new(region: 'us-east-1')
    end

    def elb

    end

    def groups
      autoscaling.describe_auto_scaling_groups(auto_scaling_group_names: [name]).auto_scaling_groups
    end

    def wait_for_instances_to_delete(group)
      autoscaling.update_auto_scaling_group(auto_scaling_group_name: group.auto_scaling_group_name, min_size: 0, max_size: 0, desired_capacity: 0)
      instance_ids = group.instances.collect{|i| i.instance_id}
      puts "waiting for #{name} to empty"
      ec2.wait_until(:instance_terminated, instance_ids: instance_ids) if instance_ids.any?

      wait_until do
        autoscaling.describe_auto_scaling_groups(auto_scaling_group_names: [group.auto_scaling_group_name]).auto_scaling_groups.first.instances.empty?
      end

      wait_for_activities_to_complete(group)
    end

    def wait_until
      Timeout.timeout(360) do
        sleep(3) until value = yield
        value
      end
    end
  end
end
