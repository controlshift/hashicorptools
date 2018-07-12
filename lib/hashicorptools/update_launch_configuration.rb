module Hashicorptools
  class UpdateLaunchConfiguration < Thor
    desc 'deploy ASG_NAME', 'recycle instances in the ASG with no downtime'
    def deploy(asg_name)
      asg = AutoScalingGroup.new(name: asg_name)
      if asg.group.nil?
        raise "could not find asg #{asg_name}"
      end
      current_count = asg.group.instances.size || 1

      if asg.group.max_size < (current_count * 2)
        raise "max size must be more than twice current count to deploy a new AMI"
      else
        # first doulbe the instance count to get new launch config live.
        asg.set_desired_instances(current_count * 2)

        # then bring the instance count back down again.
        asg.set_desired_instances(current_count)

        asg.verify_all_instances_using_correct_ami
      end
    end
  end
end
