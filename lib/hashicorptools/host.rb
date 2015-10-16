module Hashicorptools
  class Host < Thor
    
    desc 'hosts', 'list running instances'
    option :environment, required: false
    option :role, required: false
    option :name, required: false
    def hosts
      ec2 = Aws::EC2::Client.new(region: 'us-east-1')

      resp = ec2.describe_instances(filters: filters) 
      resp.reservations.each do |reservation|
        reservation.instances.each do |instance|
          name = instance.tags.find{|t| t.key == 'Name'}.value
          puts "#{name} #{instance.public_dns_name}"
        end
      end
    end

    desc 'ssh', 'ssh to the first matching instance'
    option :environment, required: false
    option :role, required: false
    option :name, required: false
    def ssh(role = '')
      ec2 = Aws::EC2::Client.new(region: 'us-east-1')

      resp = ec2.describe_instances(filters: filters(role))
      instance = resp.reservations.first.instances.first

      dns = if instance.public_dns_name.present?
        instance.public_dns_name
      else
        instance.private_dns_name
      end

      exec "ssh #{ssh_user_fragment}#{dns}"
    end

    private

    def application_environment
      if options[:environment].present?
        options[:environment]
      elsif ENV['CHANGESPROUT_APP_ENVIRONMENT'].present?
        ENV['CHANGESPROUT_APP_ENVIRONMENT']
      else
        'staging'
      end
    end

    def ssh_user_fragment
      ENV['AWS_SSH_USERNAME'].present? ? "#{ENV['AWS_SSH_USERNAME']}@" : ''
    end

    def filters(role = '')
      filters = []

      filters << {name: 'instance-state-name', values: ['running']}

      if application_environment.present?
        filters << {name: 'tag:environment', values: [ application_environment ]}
      end

      if options[:name].present?
        filters << {name: 'tag:Name', values: [ options[:name] ]}
      end

      if role.blank?
        role = options[:role].present?
      end

      if role.present?
        filters << {name: 'tag:role', values: [ role ]}
      end

      filters
    end
  end
end
