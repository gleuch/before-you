# encoding: UTF-8

Encoding.default_external = "UTF-8"
Encoding.default_internal = "UTF-8"


APP_ROOT  = File.expand_path(File.dirname(__FILE__)) if !defined?(APP_ROOT)
APP_ENV   = ENV['RACK_ENV'] if !defined?(APP_ENV) && ENV['RACK_ENV']
APP_ENV   = ENV['APP_ENV'] if !defined?(APP_ENV) && ENV['APP_ENV']
APP_ENV   = 'development' if !defined?(APP_ENV)
DEBUG     = false if !defined?(DEBUG)


# REQUIRE MODULES/GEMS
%w{yaml json active_record active_support/all addressable/uri paperclip paperclip/rack friendly_id geocoder geocoder/models/active_record mysql2 flickraw sidekiq}.each{|r| require r}

# INITIALIZERS
Dir.glob("#{APP_ROOT}/initializers/*.rb").each{|r| require r}

# CONFIG
APP_CONFIG = YAML::load(File.open("#{APP_ROOT}/config/config.yml"))[APP_ENV]

# SETUP DATABASE
ActiveRecord::Base.raise_in_transactional_callbacks = true
@DB = ActiveRecord::Base.establish_connection( YAML::load(File.open("#{APP_ROOT}/config/database.yml"))[APP_ENV] )


# REQUIRE DATABASE MODELS
Dir.glob("#{APP_ROOT}/models/**/*.rb").each{|r| require r}


# LOAD FLICKR CONFIG
if APP_CONFIG['flickr']
  FlickRaw.api_key = APP_CONFIG['flickr']['app_key']
  FlickRaw.shared_secret = APP_CONFIG['flickr']['app_secret']
end