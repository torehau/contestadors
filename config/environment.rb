# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
require 'mods.rb'

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )
  config.load_paths += %W( #{RAILS_ROOT}/app/models/configuration
                          #{RAILS_ROOT}/app/models/contest
                          #{RAILS_ROOT}/app/models/predictable
                          #{RAILS_ROOT}/app/models/predictable/championship
                          #{RAILS_ROOT}/app/repositories
                          #{RAILS_ROOT}/app/rules )

  # Specify gems that this application depends on and have them installed with rake gems:install
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"
  config.gem "fastercsv", :version => '1.5.0'
  config.gem "authlogic", :version => '2.1.3'
  config.gem 'rpx_now', :version => '0.6.12', :source => 'http://gemcutter.org'
  config.gem 'authlogic_rpx', :version => '1.1.1', :source => 'http://gemcutter.org'
  config.gem "ruleby", :version => '0.6'
  config.gem "state_machine", :version => '0.9.0'
  config.gem "uuidtools", :version => '2.1.1'
  config.gem 'will_paginate', :version => '~> 2.3.12', :source => 'http://gemcutter.org'
  config.gem 'statistics', :version => '0.1.1', :source => 'http://github.com/acatighera/statistics.git'
  config.gem 'later_dude', :version => '0.3.1'
  config.gem 'hoptoad_notifier', :version => '2.2.2'
#  config.gem "inherited_resources", :version => '0.9.5'

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer
  config.active_record.observers = :invitation_observer, :user_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'Berlin'
#  ENV['TZ'] = "UTC +02:00"

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de

  config.action_view.field_error_proc = Proc.new{ |html_tag, instance| "<span class=&quot;fieldWithErrors&quot;>#{html_tag}</span>" }

  ENV['RPX_API_KEY'] = 'a1246984717efc09ee04485fe76c2f778d9783d1'
  RPX_API_KEY = ENV['RPX_API_KEY']
  ENV['RECAPTCHA_PUBLIC_KEY']  = '6LeLJroSAAAAAAWSeDsS17hDu484NPGwXCc92eEO'
  ENV['RECAPTCHA_PRIVATE_KEY'] = '6LeLJroSAAAAAP3YdLKNsxLJEBNhNi7rU0rG45fT'

  config.action_mailer.default_url_options = {:host => 'www.contestadors.com'}
end