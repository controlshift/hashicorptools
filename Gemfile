source "http://rubygems.org"

# try to slowly migrate to v2 of the aws api
gem 'aws-sdk', '~> 2'

# this is somewhat undesirable but lets us update json gem version. We should really replace the old v1 code.
gem 'aws-sdk-v1-ruby24', git: 'https://github.com/seielit/aws-sdk-v1-ruby24.git', branch: 'aws-sdk-v1-ruby24'
gem 'dotenv', '~> 2.2', '>= 2.2.1'
gem 'thor', '>= 0.20.0'
gem 'activesupport', '>= 5.1.4'
gem 'byebug', '>= 10.0.2'
gem 'git', '> 1.3'

group :development do
  gem 'rspec', '> 3.7'
  gem 'rdoc', '> 3.12'
  gem 'bundler', '> 2.0'
  gem 'juwelier', git: 'https://github.com/flajann2/juwelier.git'
  gem 'simplecov', '>= 0'
end
