#!/usr/bin/env ruby

require 'rubygems'
require 'hpricot'
require 'open-uri'
require "socket"
require 'simplegrowl'
SimpleGrowl.set_password('growl')

class IRC
  def initialize(server, port, nick, channel)
      @server = server
      @port = port
      @nick = nick
      @channel = channel
  end
  def send(s)
      # Send a message to the irc server and print it to the screen
      # puts "--> #{s}"
      @irc.send "#{s}\n", 0 
  end
  def connect()
      # Connect to the IRC server
      @irc = TCPSocket.open(@server, @port)
      send "USER blah blah blah :blah blah"
      send "NICK #{@nick}"
      send "JOIN #{@channel}"
  end
  
  def loop( times = 1)
    while true
      # puts " loop: #{i}"
      ready = select([@irc, $stdin], nil, nil, nil)
      next if ! ready
    
      for s in ready[0]
          if s == $stdin then
              return if $stdin.eof
              s = $stdin.gets
              send s
          elsif s == @irc then
              return if @irc.eof
              s = @irc.gets
              ##handle_server_input(s)
              puts s
          end
      end
    end
  end

  
end





uri = "http://live.gizmodo.com"

posts = []

@thread = nil

@@bot = IRC.new('irc.freenode.net', '6667', "GizmodoBot", "#test-gbot")

Thread.new(@@bot) do |bot|
  bot.connect
  bot.loop  
end

# IRCEvent.add_callback('endofmotd') { |event| bot.add_channel('#test_bot_1') }



# @thread = Thread.new(bot, posts) do |bot, posts|
  loop do
    tmp_posts = []
    doc = Hpricot(open(uri) {|f| f.read })
    (doc/".post-excerpt").each do |post|
      who = post.children.first.to_plain_text.strip
      what = post.children.reject {|c| c.class.name == "Hpricot::Text" }.detect {|c| c['class'] =~ /snap_preview/ }
      text = "#{who}: #{what.to_plain_text}"

      if ! posts.include?(text)
        tmp_posts << text
        posts << text
      end

    end

    tmp_posts.reverse.each {|p| puts p; SimpleGrowl.notify(p); @@bot.send(p); puts}

    

    # puts "Resting..."
    sleep 30
  end
# end

# bot.connect

