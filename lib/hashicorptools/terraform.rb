module Hashicorptools
  class Terraform < Thor
    TERRAFORM_VERSION = '0.7.5'

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

          execute(state_path, var_file_path) do

            settings_overrides
              .merge!({ app_environment: options[:environment] }
              .merge(env_variable_keys)
              .merge(settings)
              .merge(shared_plan_variables))

            send("before_#{cmd}")

            terraform_command = "terraform #{cmd} #{variables(settings_overrides)} -state #{state_path} #{var_file_param} #{config_directory}"

            if (options[:debug])
              puts "[DEBUG] running command: '#{terraform_command}"
            end

            result = system terraform_command

            if result
              send("after_#{cmd}")
            end
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
      option :debug, :required => false
      define_method "shared_#{cmd}" do
        enforce_version!

        execute(shared_state_path) do
          terraform_command = "terraform #{cmd} #{variables(env_variable_keys.merge(settings))} -state #{shared_state_path} #{shared_config_directory}"
          if (options[:debug])
            puts "[DEBUG] running command: '#{terraform_command}"
          end
          system terraform_command
        end
      end
    end

    desc 'output', 'terraform output'
    option :environment, :required => true
    option :name, :required => true
    def output
      execute(state_path) do
        system output_cmd(state_path, options[:name])
      end
    end

    desc 'shared_output', 'terraform output for shared plan'
    option :name, :required => true
    def shared_output
      execute(shared_state_path) do
        system output_cmd(shared_state_path, options[:name])
      end
    end

    desc 'taint', 'terraform taint'
    option :environment, :required => true
    option :name, :required => true
    option :module, :required => false
    def taint
      execute(state_path) do
        if options[:module].present?
          system "terraform taint -module #{options[:module]} -state #{state_path} #{options[:name]}"
        else
          system "terraform taint -state #{state_path} #{options[:name]}"
        end
      end
    end

    desc 'shared_taint', 'terraform taint for shared plan'
    option :name, :required => true
    option :module, :required => false
    def shared_taint
      execute(shared_state_path) do
        if options[:module].present?
          system "terraform taint -module #{options[:module]} -state #{shared_state_path} #{options[:name]}"
        else
          system "terraform taint -state #{shared_state_path} #{options[:name]}"
        end
      end
    end

    desc 'show', 'terraform show'
    option :environment, :required => true
    def show
      execute(state_path) do
        system "terraform show #{state_path}"
      end
    end

    desc 'shared_show', 'terraform show for shared plan'
    def shared_show
      execute(shared_state_path) do
        system "terraform show #{shared_state_path}"
      end
    end

    [ {commands: [:decrypt, :encrypt], file_path_method: :state_path, desc: 'upstream terraform changes'},
      {commands: [:shared_decrypt, :shared_encrypt], file_path_method: :shared_state_path, desc: 'upstream shared terraform changes'},
      {commands: [:var_file_decrypt, :var_file_encrypt], file_path_method: :var_file_path, desc: 'tfvars file'} ].each do |crypto_commands|

        desc crypto_commands[:commands][0], "decrypt #{crypto_commands[:desc]}"
        unless crypto_commands.to_s.match(/shared_.+/)
          option :environment, :required => true
        end
        define_method crypto_commands[:commands][0] do
          file_path = send(crypto_commands[:file_path_method])
          decrypt_file(file_path)
        end

        desc crypto_commands[:commands][1], "encrypt #{crypto_commands[:desc]}"
        unless crypto_commands.to_s.match(/shared_.+/)
          option :environment, :required => true
        end
        define_method crypto_commands[:commands][1] do
          file_path = send(crypto_commands[:file_path_method])
          encrypt_file(file_path)
        end
    end

    desc "console", "interactive session"
    def console
      require 'pry-byebug'
      binding.pry
    end

    protected

    def var_file_param
      File.exist?(var_file_path) ?
        "-var-file #{var_file_path}" :
        ""
    end

    def execute(state_file_path, var_file_path=nil)
      decrypt_file(state_file_path)
      if var_file_path
        decrypt_file(var_file_path)
      end

      begin
        yield
      rescue StandardError => e
        puts e.message
        puts e.backtrace
      ensure
        encrypt_file(state_file_path)
        if var_file_path
          delete_decrypted_var_file
        end
      end
    end

    def delete_decrypted_var_file
      return unless File.exist?(var_file_path)

      enforce_cryptography_dependencies
      if !File.exist?("#{var_file_path}.enc")
        encrypt_file(var_file_path)
      end

      File.delete(var_file_path)
    end

    def encrypt_file(file_path)
      enforce_cryptography_dependencies
      if File.exist?(file_path)
        system "openssl enc -aes-256-cbc -salt -in #{file_path} -out #{file_path}.enc -k #{ENV['TFSTATE_ENCRYPTION_PASSWORD']}"
      end
    end

    def decrypt_file(file_path, enforce_file_existence=false)
      enforce_cryptography_dependencies
      if File.exist?("#{file_path}.enc")
        system "openssl enc -aes-256-cbc -d -in #{file_path}.enc -out #{file_path} -k #{ENV['TFSTATE_ENCRYPTION_PASSWORD']}"
      elsif enforce_file_existence
        raise "Could not find #{file_path}.enc"
      end
    end

    def state_path
      "#{config_environment_path}/#{options[:environment]}.tfstate"
    end

    def shared_state_path
      "#{shared_config_directory}/shared.tfstate"
    end

    def var_file_path
      "#{config_environment_path}/variables.tfvars"
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

    def output_variables(state_file_path)
      raw_plan_output = `#{output_cmd(state_file_path)}`
      parse_key_value_variables(raw_plan_output)
    end

    def var_file_variables
      raise "Vars file #{var_file_path} does not exist" unless File.exist?(var_file_path)

      raw_var_file_variables = File.read(var_file_path)
      parse_key_value_variables(raw_var_file_variables)
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

    def enforce_cryptography_dependencies
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
      {} # override me to pass environmental variables into the terraform plan
    end

    def shared_plan_variables
      decrypt_file(shared_state_path, false)
      if File.exist?(shared_state_path)
        output_variables(shared_state_path)
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

    def dynect
      @dynect ||= DynectRest.new("controlshiftlabs", ENV['DYNECT_USERNAME'], ENV['DYNECT_PASSWORD'], "controlshiftlabs.com")
    end

    def dns_record_exists?(parent_node_fqdn, record)
      dynect.node_list(nil, parent_node_fqdn).include?(record.fqdn)
    end

    private

    def parse_key_value_variables(vars_string)
      vars = {}
      vars_string.split("\n").each do |string_var|
        next if string_var.blank?
        key, value = string_var.split("=")
        vars[key.strip] = value.strip.gsub('"', '')
      end

      vars
    end
  end
end
