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
    def ssh
      ec2 = Aws::EC2::Client.new(region: 'us-east-1')

      resp = ec2.describe_instances(filters: filters) 
      dns = resp.reservations.first.instances.first.public_dns_name
      exec "ssh #{dns}"
    end


    private 

    def filters
      filters = []

      filters << {name: 'instance-state-name', values: ['running']}

      if options[:environment].present?
        filters << {name: 'tag:environment', values: [ options[:environment] ]}
      end

      if options[:name].present?
        filters << {name: 'tag:Name', values: [ options[:name] ]}
      end

      filters
    end
  end
end