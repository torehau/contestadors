require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module Contestadors
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths += %W(#{config.root}/lib/ext)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer
    config.active_record.observers = :invitation_observer, :user_observer, :participation_observer, :comment_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.time_zone = 'Berlin'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation]

    #config.action_view.field_error_proc = Proc.new{ |html_tag, instance| "<span class=&quot;fieldWithErrors&quot;>#{html_tag}</span>" }
    config.action_view.field_error_proc = Proc.new { |html_tag, instance| "#{html_tag}".html_safe }

    #ENV['RPX_API_KEY'] = 'a1246984717efc09ee04485fe76c2f778d9783d1'
    ##RPX_API_KEY = ENV['RPX_API_KEY']
    #ENV['RECAPTCHA_PUBLIC_KEY']  = '6LeLJroSAAAAAAWSeDsS17hDu484NPGwXCc92eEO'
    #ENV['RECAPTCHA_PRIVATE_KEY'] = '6LeLJroSAAAAAP3YdLKNsxLJEBNhNi7rU0rG45fT'

    config.action_mailer.default_url_options = {:host => 'www.contestadors.com'}

    config.after_initialize do # so rake gems:install works
      # use your own (e.g. from account with all features enabled) or the default
      RPXNow.api_key = (File.exist?('config/rpx_now_api_key') ? File.read('config/rpx_now_api_key').strip : 'a1246984717efc09ee04485fe76c2f778d9783d1')
    end
  end
end
