require 'variables'

class Terraform < Thor
  TERRAFORM_VERSION = '0.6.3'

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

    define_method cmd do
      send("_#{cmd}")
    end

    no_commands do
      define_method "_#{cmd}" do |asg_colors = nil, settings_overrides = {}|
        enforce_version!
        raise 'invalid environment' unless ['staging', 'production'].include?(options[:environment])

        settings_overrides.merge!({app_environment: options[:environment]}.merge(env_variable_keys))

        send("before_#{cmd}")
        if system "terraform #{cmd} #{variables(settings_overrides)} -state #{state_path} #{config_directory}"
          send("after_#{cmd}")
        end
      end

      define_method "before_#{cmd}" do
        # no-op
      end
    end

    no_commands do
      define_method "after_#{cmd}" do
        encrypt_tfstate
      end
    end
  end

  desc 'output', 'terraform output'
  option :environment, :required => true
  option :name, :required => true
  def output
    system output_cmd(options[:name])
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

  desc 'decrypt', 'decrypt upstream terraform changes into local statue'
  option :environment, :required => true
  def decrypt
    decrypt_tfstate
  end

  desc "console", "interactive session"
  def console
    require 'pry-byebug'
    binding.pry
  end

  protected

  def encrypt_tfstate
    if File.exist?(state_path)
      system "openssl enc -aes-256-cbc -salt -in #{state_path} -out #{state_path}.enc -k #{ENV['TFSTATE_ENCRYPTION_PASSWORD']}"
    end
  end

  def decrypt_tfstate
    if File.exist?("#{state_path}.enc")
      system "openssl enc -aes-256-cbc -d -in #{state_path}.enc -out #{state_path} -k #{ENV['TFSTATE_ENCRYPTION_PASSWORD']}"
    end
  end

  def state_path
    "#{config_environment_path}/#{options[:environment]}.tfstate"
  end

  def config_directory
    "config/infrastructure/#{infrastructure}"
  end

  def config_environment_path
    "#{config_directory}/environments/#{options[:environment]}"
  end

  def infrastructure
    raise 'implement me'
  end

  def output_cmd(name)
    "terraform output -state=#{state_path} #{name}"
  end

  def output_variable(name)
    `#{output_cmd(name)}`.chomp
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

  def env_variable_keys
    items = {}

    [:postgres_password, :embedly_key, :honeybadger_api_key, :honeybadger_public_key, :statsd_host, :statsd_namespace,
     :change_org_key, :change_org_secret, :airbrake_api_key, :sendgrid_username, :sendgrid_password, :open_exchange_rate_id,
     :fog_directory].each do |key|
      items[key] = ENV[key.to_s.upcase]
    end
    items
  end

  def current_tfstate
    return @current_tfstate if defined?(@current_tfstate)
    raw_conf = File.read(state_path)
    @current_tfstate = JSON.parse(raw_conf)
  end
end
