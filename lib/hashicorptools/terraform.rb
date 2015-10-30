module Hashicorptools
  class Terraform < Thor
    TERRAFORM_VERSION = '0.6.5'

    include Ec2Utilities
    include Variables

    desc 'bootstrap', 'terraform a new infrastructure from scratch'
    option :environment, :required => true
    def bootstrap
      apply
    end

    [:apply, :plan, :destroy, :pull, :refresh].each do |cmd|
      desc cmd, "terraform #{cmd}"
      option :environment, :required => true
      option :debug, :required => false

      define_method cmd do
        send("_#{cmd}")
      end

      no_commands do
        define_method "_#{cmd}" do |settings_overrides = {}|
          enforce_version!
          raise 'invalid environment' unless ['staging', 'production'].include?(options[:environment])

          settings_overrides
            .merge!({ app_environment: options[:environment] }
            .merge(env_variable_keys)
            .merge(settings)
            .merge(shared_plan_variables))

          decrypt_tfstate(state_path)

          begin
            send("before_#{cmd}")


            if File.exist?("#{config_environment_path}/variables.tfvars")
              terraform_command = "terraform #{cmd} #{variables(settings_overrides)} -state #{state_path} -var-file #{config_environment_path}/variables.tfvars #{config_directory}"
            else
              terraform_command = "terraform #{cmd} #{variables(settings_overrides)} -state #{state_path} #{config_directory}"
            end

            if (options[:debug])
              puts "[DEBUG] running command: '#{terraform_command}"
            end
            if system terraform_command
              send("after_#{cmd}")
            end
          rescue StandardError => e
            puts e.message
            puts e.backtrace
          ensure
            # need to always ensure the most recent tfstate is encrypted again.
            encrypt_tfstate(state_path)
          end

        end

        define_method "before_#{cmd}" do
          # no-op
        end
      end

      no_commands do
        define_method "after_#{cmd}" do
          # no-op
        end
      end

      desc cmd, "terraform #{cmd} for shared plan"
      define_method "shared_#{cmd}" do
        enforce_version!

        decrypt_tfstate(shared_state_path)

        begin
          system "terraform #{cmd} #{variables(env_variable_keys.merge(settings))} -state #{shared_state_path} #{shared_config_directory}"
        rescue StandardError => e
          puts e.message
          puts e.backtrace
        ensure
          # need to always ensure the most recent tfstate is encrypted again.
          encrypt_tfstate(shared_state_path)
        end
      end
    end

    [:shared_apply, :shared_plan, :shared_destroy, :shared_pull, :shared_refresh].each do |cmd|

    end

    desc 'output', 'terraform output'
    option :environment, :required => true
    option :name, :required => true
    def output
      system output_cmd(state_path, options[:name])
    end

    desc 'taint', 'terraform taint'
    option :environment, :required => true
    option :name, :required => true
    def taint
      system "terraform taint -state #{state_path} #{options[:name]}"
    end

    desc 'show', 'terraform show'
    option :environment, :required => true
    def show
      system "terraform show #{state_path}"
    end

    desc 'decrypt', 'decrypt upstream terraform changes into local status'
    option :environment, :required => true
    def decrypt
      decrypt_tfstate(state_path, true)
    end

    desc 'shared_decrypt', 'decrypt upstream shared terraform changes into local status'
    def shared_decrypt
      decrypt_tfstate(shared_state_path, true)
    end

    desc 'encrypt', 'encrypt terraform local status'
    option :environment, :required => true
    def encrypt
      encrypt_tfstate(state_path)
    end

    desc 'shared_encrypt', 'encrypt shared terraform state local status'
    def shared_encrypt
      encrypt_tfstate(shared_state_path)
    end

    desc "console", "interactive session"
    def console
      require 'pry-byebug'
      binding.pry
    end

    protected

    def encrypt_tfstate(state_file_path)
      enforce_tfstate_dependencies
      if File.exist?(state_file_path)
        system "openssl enc -aes-256-cbc -salt -in #{state_file_path} -out #{state_file_path}.enc -k #{ENV['TFSTATE_ENCRYPTION_PASSWORD']}"
      end
    end

    def decrypt_tfstate(state_file_path, enforce_file_existence=false)
      enforce_tfstate_dependencies
      if File.exist?("#{state_file_path}.enc")
        system "openssl enc -aes-256-cbc -d -in #{state_file_path}.enc -out #{state_file_path} -k #{ENV['TFSTATE_ENCRYPTION_PASSWORD']}"
      elsif enforce_file_existence
        raise "Could not find #{state_file_path}.enc"
      end
    end

    def state_path
      "#{config_environment_path}/#{options[:environment]}.tfstate"
    end

    def shared_state_path
      "#{shared_config_directory}/shared.tfstate"
    end

    def config_directory
      "config/infrastructure/#{infrastructure}"
    end

    def shared_config_directory
      "config/infrastructure/#{infrastructure}/shared"
    end

    def config_environment_path
      "#{config_directory}/environments/#{options[:environment]}"
    end

    def infrastructure
      raise 'implement me'
    end

    def output_cmd(state_file_path, name=nil)
      "terraform output -state=#{state_file_path} #{name}"
    end

    def output_variable(state_file_path, name)
      `#{output_cmd(state_file_path, name)}`.chomp
    end

    def terraform_version
      version_string = `terraform version`.chomp
      version = /(\d+.\d+.\d+)/.match(version_string)
      version[0]
    end

    def enforce_version!
      if Gem::Version.new(terraform_version) < Gem::Version.new(TERRAFORM_VERSION)
        raise "Terraform #{terraform_version} is out of date, please upgrade"
      end
    end

    def enforce_tfstate_dependencies
      raise "must supply TFSTATE_ENCRYPTION_PASSWORD environmental variable" if ENV['TFSTATE_ENCRYPTION_PASSWORD'].blank?
    end

    def settings
      {} # override me to pass more variables into the terraform plan.
    end

    def asg_launch_config_name(asg_name)
      asg_client = Aws::AutoScaling::Client.new(region: 'us-east-1')
      group = asg_client.describe_auto_scaling_groups(auto_scaling_group_names: [asg_name]).auto_scaling_groups.first
      group.try(:launch_configuration_name)
    end

    def env_variable_keys
      items = {}

      [:postgres_password, :embedly_key, :honeybadger_api_key, :honeybadger_public_key, :statsd_host, :statsd_namespace,
       :change_org_key, :change_org_secret, :airbrake_api_key, :sendgrid_username, :sendgrid_password, :open_exchange_rate_id,
       :fog_directory].each do |key|
        items[key] = ENV[key.to_s.upcase]
      end
      items
    end

    def shared_plan_variables
      decrypt_tfstate(shared_state_path, false)
      if File.exist?(shared_state_path)
        raw_shared_plan_output = `#{output_cmd(shared_state_path)}`
        shared_variables = {}
        raw_shared_plan_output.split("\n").each do |output_var|
          key, value = output_var.split("=")
          shared_variables[key.strip] = value.strip
        end

        shared_variables
      else
        {}
      end
    end

    def fetch_terraform_modules
      system "terraform get -update=true #{config_directory}"
    end

    def current_tfstate
      return @current_tfstate if defined?(@current_tfstate)
      raw_conf = File.read(state_path)
      @current_tfstate = JSON.parse(raw_conf)
    end

    def read_config_file(path)
      File.new('config/' + path).read
      template = ERB.new File.new("config/#{path}").read, nil, "%"
      template.result(OpenStruct.new(options).instance_eval { binding })
    end
  end
end
