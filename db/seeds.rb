# encoding: UTF-8

require File.join( File.expand_path(File.dirname(__FILE__)), '..' , 'config.rb')

(0..25).each do
  ip = [rand(255),rand(255),rand(255),rand(255)].join('.')
  l = Location.where(ip_address: ip).first_or_create do |u|
    u.ip_address = ip
    u.useragent = 'dev'
  end
  puts l.new_record? ? l.errors.inspect : l.inspect
end
