NUMBER_OF_AMIS_TO_KEEP = 2

class Packer < Thor
  include ::Ec2Utilities

  desc "build", "creates an AMI from the current config"
  def build
    system "packer build \
        -var 'aws_access_key=#{ENV['AWS_ACCESS_KEY_ID']}' \
        -var 'aws_secret_key=#{ENV['AWS_SECRET_ACCESS_KEY']}' \
        -var 'source_ami=#{source_ami_id}' \
        -var 'ami_tag=#{tag_name}' \
        -var 'cookbook_name=#{cookbook_name}' \
        #{ami_config_path}"

    clean_amis
  end

  desc "validate", "validates the packer config"
  def validate
    system "packer validate #{ami_config_path}"
  end

  desc "console", "interactive session"
  def console
    require 'pry-byebug'
    ec2 = AWS::EC2.new
    binding.pry
  end

  desc "list", "list all available telize amis"
  def list
    amis.each do |ami|
      puts ami.image_id
    end
  end

  desc "clean", "clean old AMIs that are no longer neaded"
  def clean
    clean_amis
  end

  protected

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
    "config/amis/#{tag_name}.json"
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
