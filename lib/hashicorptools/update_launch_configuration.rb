module Hashicorptools
  class UpdateLaunchConfiguration < Thor
    desc 'deploy', 'cycle a new LC into prod'
    def deploy(asg_name)
      asg = AutoScalingGroup.new(name: asg_name)
      if asg.group.nil?
        raise "could not find asg #{asg_name}"
      end
      current_count = asg.group.instances.size

      if asg.group.max_size < (current_count * 2)
        raise "max size must be more than twice current count to deploy a new AMI"
      else
        # first doulbe the instance count to get new launch config live.
        asg.set_desired_instances(current_count * 2)

        # then bring the instance count back down again.
        asg.set_desired_instances(current_count)
      end
    end
  end
end
