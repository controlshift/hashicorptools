module Variables
  def aws_credentials_settings(settings_overrides = {})
    {aws_access_key: ENV['AWS_ACCESS_KEY_ID'],
     aws_secret_key: ENV['AWS_SECRET_ACCESS_KEY']}.merge(settings_overrides)
  end

  def variables(settings_overrides = {})
    aws_credentials_settings(settings_overrides).collect{|key,value| "-var '#{key}=#{value}'" }.join(' ')
  end
end
