#\ -s puma -E production -p 9292

require 'rubygems'

require 'bundler'
Bundler.require

require './app'
require './middleware/websockets'

use BeforeYou::Backend

run BeforeYou::App



# root_dir = File.dirname(__FILE__)
# 
# # set :environment, :production
# set :environemnt, :development
# set :root,        root_dir
# set :app_file,    File.join(root_dir, 'app.rb')
# set :logging,     :true
# 
# disable :run
# enable :logging
# 
# 
# log = File.new("log/#{Sinatra::Application.environment.to_s}.log", "a+")
# STDOUT.reopen(log)
# STDERR.reopen(log)
# $stdout.reopen(log)
# $stderr.reopen(log)
# 
# $stderr.sync = true
# $stdout.sync = true
# 
# 
# map '/' do
#   require "#{root_dir}/app"
#   run BeforeYou
# end