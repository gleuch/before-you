# encoding: UTF-8

Encoding.default_external = "UTF-8"
Encoding.default_internal = "UTF-8"


APP_ROOT  ||= File.expand_path(File.dirname(__FILE__))
APP_ENV   ||= 'development'
DEBUG     ||= false


# REQUIRE MODULES/GEMS
%w{yaml json active_record active_support/all addressable/uri paperclip friendly_id geocoder geocoder/models/active_record mysql2}.each{|r| require r}

# INITIALIZERS
Dir.glob("#{APP_ROOT}/initializers/*.rb").each{|r| require r}

# CONFIG
APP_CONFIG = YAML::load(File.open("#{APP_ROOT}/config.yml"))[APP_ENV]

# SETUP DATABASE
@DB = ActiveRecord::Base.establish_connection( YAML::load(File.open("#{APP_ROOT}/database.yml"))[APP_ENV] )

# REQUIRE DATABASE MODELS
Dir.glob("#{APP_ROOT}/models/**/*.rb").each{|r| require r}