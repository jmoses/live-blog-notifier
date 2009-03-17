#!/usr/bin/env ruby

require 'rubygems'
require 'ruby-growl'

class SimpleGrowl
  def self.set_password(str)
    @@password = str
  end
  
  def self.notify( msg, title = "SimpleGrowl Notification")
    @@growl ||= Growl.new('localhost', 'SimpleGrowl', %w( notification ), %w(notification), (@@password or nil) )
    
    @@growl.notify('notification', title, msg )
  end
end
