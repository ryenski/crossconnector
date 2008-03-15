# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger        = SyslogLogger.new


# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors if you bad email addresses should just be ignored
config.action_mailer.raise_delivery_errors = false

config.action_controller.session_store = :active_record_store

ActionMailer::Base.delivery_method = :sendmail

module App
  CONFIG = {    
    :app_url => 'http://www.crossconnector.com/',
    :app_domain => 'crossconnector.com',
    :app_ftp_root => '/Volumes/MirrorDisk/etc/AppFiles',
    :theme => "orange_crush"
  }
end

#b55d523d254174c2f318ec0e2afee5021cb70ff4