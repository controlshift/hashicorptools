require 'aws-sdk-ec2'

module Hashicorptools
  module Ec2Utilities
    def current_ami(tag = tag_name)
      amis(tag).first
    end

    def amis(tag = tag_name)
      images = ec2.describe_images({owners: ['self'], filters: [{name: 'tag:Name', values: [tag]}]}).images
      sort_by_created_at(images)
    end

    def ec2
      return @_ec2 unless @_ec2.nil?

      reg = if self.methods.include?(:region)
              self.region
            else
              'us-east-1'
            end

      @_ec2 = Aws::EC2::Client.new(region: reg)
    end

    def vpc_with_name(name)
      ec2.describe_vpcs({filters: [{name: 'tag:Name', values: [name]}]}).vpcs.first
    end

    def internet_gateway_for_vpc(vpc_id)
      ec2.describe_internet_gateways({filters: [{name: 'attachment.vpc-id', values: [vpc_id]}]}).internet_gateways.first
    end

    def sort_by_created_at(collection)
      collection.sort{|a, b| b.creation_date <=> a.creation_date }
    end
  end
end
