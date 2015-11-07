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
        current_size = group.instances.size
        puts "asg currently has #{current_size} instances"
        current_size == desired_instances
      end

      puts "waiting for scaling events to finish"
      groups.each do |group|
        wait_for_activities_to_complete(group)
      end
      puts "all #{desired_instances} scaling activities successful."
      wait_until_instances_ready
      puts "all #{desired_instances} instances ready."
    end

    def wait_until_instances_ready
      wait_until do
        group.instances.any?
      end

      pending_instance_ids = group.instances.find_all{|i| ['Pending', 'Pending:Wait', 'Pending:Proceed'].include?(i.lifecycle_state) }.collect{|i| i.instance_id}
      shutting_down_ids =  group.instances.find_all{|i| ['Terminating', 'Terminating:Wait', 'Terminating:Proceed'].include?(i.lifecycle_state) }.collect{|i| i.instance_id}

      ec2.wait_until(:instance_running, instance_ids: pending_instance_ids) if pending_instance_ids.any?
      ec2.wait_until(:instance_terminated, instance_ids: shutting_down_ids)  if shutting_down_ids.any?

      # now that all of the instances starting up / shutting down have settled, we can verify that running instances are healthy.
      puts "waiting for instance status checks to pass.."
      wait_until do
        puts "checking instance statuses"
        resp = ec2.describe_instance_status(instance_ids: group.instances.collect{|i| i.instance_id})
        resp.instance_statuses.all?{|s| s.system_status.status == 'ok'}
      end

      puts "waiting for ELB health checks to pass..."
      wait_until do
        all_load_balancers_at_full_health?
      end

      wait_for_activities_to_complete(group)
    end

    def group
      groups.first
    end

    def all_load_balancers_at_full_health?
      names = group.load_balancer_names
      names.each do |lb_name|
        puts "checking health of instances in #{lb_name}"
        inst_health = elb.describe_instance_health({load_balancer_name: lb_name})
        unless inst_health.instance_states.all?{|inst| inst.state == 'InService'}
          return false
        end
      end
      return true
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
        unless activity.status_code == 'Successful' || activity.status_code == 'Failed' || activity.status_code == 'Cancelled'
          puts "waiting for #{activity.status_code} activity to finish: #{activity.description}..."
          wait_until(6000) do
            activity = autoscaling.describe_scaling_activities(auto_scaling_group_name: group.auto_scaling_group_name, activity_ids: [activity.activity_id]).activities.first
            puts "#{activity.status_code}"
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
      @elb ||= Aws::ElasticLoadBalancing::Client.new(region: 'us-east-1')
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

    def wait_until(max_time=420)
      Timeout.timeout(max_time) do
        seconds_to_sleep = 10

        until value = yield do
          sleep(seconds_to_sleep)
          seconds_to_sleep *= 3
        end

        value
      end
    end
  end
end
